class Api::V1::LeetcodeAuthController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cors_headers
  before_action :authenticate_user!, except: [ :check_username_availability ]

  def authenticate
    leetcode_cookies = if params[:cookies].present?
                        params[:cookies].to_unsafe_h
    elsif params[:leetcode_auth]&.dig(:cookies).present?
                        params[:leetcode_auth][:cookies].to_unsafe_h
    else
                        {}
    end

    Rails.logger.info "Received cookies: #{leetcode_cookies.inspect}"

    leetcode_service = LeetcodeService.new(leetcode_cookies)

    unless leetcode_service.validate_cookies
      render json: { error: "Invalid LeetCode credentials" }, status: :unauthorized
      return
    end

    profile = leetcode_service.fetch_user_profile

    unless profile
      Rails.logger.error "Failed to fetch LeetCode profile"
      render json: { error: "Could not fetch LeetCode profile. Please try again." }, status: :unprocessable_entity
      return
    end

    Rails.logger.info "Successfully fetched profile: #{profile.inspect}"

    existing_user = User.find_by_leetcode_username(profile[:username])
    if existing_user && existing_user.id != current_user.id
      render json: {
        error: "LeetCode account already linked",
        details: "The LeetCode username '#{profile[:username]}' is already linked to another account (#{existing_user.email})",
        leetcode_username: profile[:username],
        existing_user_email: existing_user.email
      }, status: :conflict
      return
    end

    user = current_user
    user.leetcode_username = profile[:username]

    user.leetcode_solved_count = profile[:solved_count]
    user.leetcode_total_count = profile[:total_active_days]
    user.leetcode_rank = profile[:rank]

    user.leetcode_cookies = leetcode_cookies.to_json
    user.leetcode_last_sync = Time.current

    if user.save
      render json: {
        success: true,
        action: user.new_record? ? "account_created" : "account_linked",
        redirect_url: "#{request.base_url}/dashboard",
        user: {
          id: user.id,
          leetcode_username: user.leetcode_username,
          email: user.email,
          leetcode_stats: {
            solved_count: profile[:solved_count],
            total_active_days: profile[:total_active_days],
            rank: profile[:rank]
          }
        }
      }
    else
      error_messages = user.errors.full_messages.join(", ")
      render json: {
        error: "Failed to save user",
        details: error_messages,
        validation_errors: user.errors.as_json
      }, status: :unprocessable_entity
    end
  end

  def sync_profile
    user = current_user
    return render json: { error: "Unauthorized" }, status: :unauthorized unless user

    cookies = if user.leetcode_cookies.is_a?(String)
                JSON.parse(user.leetcode_cookies)
    else
                user.leetcode_cookies
    end

    leetcode_service = LeetcodeService.new(cookies)
    profile = leetcode_service.fetch_user_profile

    if profile
      user.update(
        leetcode_solved_count: profile[:solved_count],
        leetcode_total_count: profile[:total_active_days],
        leetcode_rank: profile[:rank],
        leetcode_last_sync: Time.current
      )

      render json: {
        leetcode_stats: {
          solved_count: profile[:solved_count],
          total_active_days: profile[:total_active_days],
          rank: profile[:rank]
        }
      }
    else
      render json: { error: "Failed to sync profile" }, status: :unprocessable_entity
    end
  end

  def sync_submissions
    user = current_user
    return render json: { error: "Unauthorized" }, status: :unauthorized unless user

    cookies = if user.leetcode_cookies.is_a?(String)
                JSON.parse(user.leetcode_cookies)
    else
                user.leetcode_cookies
    end

    leetcode_service = LeetcodeService.new(cookies)

    # First validate cookies
    unless leetcode_service.validate_cookies
      render json: {
        success: false,
        error: "LeetCode session expired. Please re-link your account.",
        requires_relink: true
      }, status: :unauthorized
      return
    end

    # Fetch profile first
    profile = leetcode_service.fetch_user_profile

    if profile
      # Update user stats
      user.update(
        leetcode_solved_count: profile[:solved_count],
        leetcode_total_count: profile[:total_active_days],
        leetcode_rank: profile[:rank],
        leetcode_last_sync: Time.current
      )

      # Try to fetch submissions, but don't fail the entire sync if it fails
      api_submissions = []
      total_active_days = profile[:total_active_days] || 0

      begin
        api_submissions = leetcode_service.fetch_recent_submissions || []
        Rails.logger.info "Successfully fetched #{api_submissions.length} submissions during sync"

        # Store submissions in database
        if api_submissions.any?
          synced_submissions = Submission.sync_from_api(user, api_submissions) # Rails cache
          Rails.logger.info "Synced #{synced_submissions.length} submissions to database"

          # Calculate actual active days from submissions if we have them
          unique_dates = api_submissions.map do |submission|
            Time.at(submission[:timestamp]).to_date
          end.uniq
          total_active_days = unique_dates.count
        end
      rescue => e
        Rails.logger.warn "Failed to fetch submissions during sync: #{e.message}"
      end

      # Get recent submissions from database for response
      recent_submissions = Submission.recent_for_user(user.id, 10)

      render json: {
        success: true,
        leetcode_stats: {
          solved_count: profile[:solved_count],
          total_active_days: total_active_days,
          rank: profile[:rank]
        },
        submissions: Submission.to_api_array(recent_submissions),
        last_sync: Time.current.iso8601
      }
    else
      render json: {
        success: false,
        error: "Failed to sync data from LeetCode"
      }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error syncing submissions: #{e.message}"
    render json: {
      success: false,
      error: "An error occurred while syncing. Please try again."
    }, status: :internal_server_error
  end

  def check_username_availability
    username = params[:username]

    username = username.strip if username

    if username.blank?
      render json: { error: "Username cannot be empty or contain only whitespace" }, status: :bad_request
      return
    end

    is_available = User.leetcode_username_available?(username)
    existing_user = User.find_by_leetcode_username(username)

    render json: {
      username: username,
      available: is_available,
      existing_user: existing_user ? {
        id: existing_user.id,
        email: existing_user.email
      } : nil
    }
  end

  def refresh_session
    user = current_user
    return render json: { error: "Unauthorized" }, status: :unauthorized unless user

    if user.leetcode_cookies.blank?
      render json: {
        error: "No LeetCode account linked",
        message: "Please link your LeetCode account first"
      }, status: :bad_request
      return
    end

    # Schedule background refresh
    LeetcodeSessionRefreshJob.perform_later(user.id, force_refresh: true)

    render json: {
      success: true,
      message: "Session refresh initiated. Please check back in a few minutes.",
      user_id: user.id,
      leetcode_username: user.leetcode_username
    }
  end

  def session_health
    user = current_user
    return render json: { error: "Unauthorized" }, status: :unauthorized unless user

    if user.leetcode_cookies.blank?
      render json: {
        healthy: false,
        message: "No LeetCode account linked",
        last_sync: nil
      }
      return
    end

    begin
      healthy = user.leetcode_session_healthy?

      render json: {
        healthy: healthy,
        last_sync: user.leetcode_last_sync&.iso8601,
        leetcode_username: user.leetcode_username,
        activity_level: user.determine_activity_level,
        refresh_interval: user.calculate_refresh_interval.to_i
      }
    rescue => e
      Rails.logger.error "Error checking session health: #{e.message}"
      render json: {
        healthy: false,
        error: "Failed to check session health",
        last_sync: user.leetcode_last_sync&.iso8601
      }, status: :internal_server_error
    end
  end

  private

  def set_cors_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
  end
end
