class Api::V1::LeetcodeAuthController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cors_headers
  before_action :authenticate_user!, except: [:check_username_availability]
  
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
      render json: { error: 'Invalid LeetCode credentials' }, status: :unauthorized
      return
    end
    
    profile = leetcode_service.fetch_user_profile
    
    unless profile
      Rails.logger.error "Failed to fetch LeetCode profile"
      render json: { error: 'Could not fetch LeetCode profile. Please try again.' }, status: :unprocessable_entity
      return
    end
    
    Rails.logger.info "Successfully fetched profile: #{profile.inspect}"
    
    existing_user = User.find_by_leetcode_username(profile[:username])
    if existing_user && existing_user.id != current_user.id
      render json: { 
        error: 'LeetCode account already linked', 
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
        action: user.new_record? ? 'account_created' : 'account_linked',
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
      error_messages = user.errors.full_messages.join(', ')
      render json: { 
        error: 'Failed to save user', 
        details: error_messages,
        validation_errors: user.errors.as_json
      }, status: :unprocessable_entity
    end
  end
  
  def sync_profile
    user = current_user
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless user
    
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
      render json: { error: 'Failed to sync profile' }, status: :unprocessable_entity
    end
  end

  def check_username_availability
    username = params[:username]
    
    username = username.strip if username
    
    if username.blank?
      render json: { error: 'Username cannot be empty or contain only whitespace' }, status: :bad_request
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
  
  private
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end
end
