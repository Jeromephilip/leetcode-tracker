class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user

    if @user.leetcode_cookies.nil?
      render :link_account
      return
    end

    begin
      cookies = parse_cookies(@user.leetcode_cookies)

      if cookies.empty?
        @error = "Unable to parse LeetCode cookies. Please re-link your account."
        @leetcode_service = nil
        @recent_submissions = []
        @leetcode_stats = {}
      else
        @leetcode_service = LeetcodeService.new(cookies)

        @leetcode_profile = @leetcode_service.fetch_user_profile
        if @leetcode_profile
          Rails.logger.info "LeetCode profile fetched: #{@leetcode_profile.inspect}"

          # Update user stats in database
          @user.update(
            leetcode_solved_count: @leetcode_profile[:solved_count],
            leetcode_total_count: @leetcode_profile[:total_count] || @leetcode_profile[:total_active_days],
            leetcode_rank: @leetcode_profile[:rank],
            leetcode_last_sync: Time.current
          )

          # Set stats for the view - handle both data structures
          @leetcode_stats = {
            solved_count: @leetcode_profile[:solved_count] || 0,
            total_count: @leetcode_profile[:total_count] || @leetcode_profile[:total_active_days] || 0,
            rank: @leetcode_profile[:rank] || "N/A",
            total_active_days: @leetcode_profile[:total_active_days] || 0
          }
        else
          Rails.logger.warn "Failed to fetch LeetCode profile"
          @leetcode_stats = {
            solved_count: 0,
            total_count: 0,
            rank: "N/A",
            total_active_days: 0
          }
        end

        # Load recent submissions from cache/db instead of fetching from API
        @recent_submissions = Submission.recent_for_user(@user.id, 10)
        Rails.logger.info "Loaded #{@recent_submissions.length} recent submissions from database"
      end
    rescue => e
      Rails.logger.error "Error in dashboard controller: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
      @error = "An error occurred while fetching your LeetCode data. Please try again."
      @leetcode_stats = {
        solved_count: 0,
        total_count: 0,
        rank: "N/A",
        total_active_days: 0
      }
      @recent_submissions = []
    end
  end

  def logout
    sign_out(current_user)
    redirect_to root_path, notice: "Successfully logged out"
  end

  def link_account
  end

  private

  def current_user
    super
  end

  def parse_cookies(cookies)
    Rails.logger.info "Raw cookies type: #{cookies.class}, value: #{cookies.inspect}"

    if cookies.is_a?(String)
      begin
        JSON.parse(cookies)
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parse error: #{e.message}"
        Rails.logger.error "Cookies string: #{cookies}"

        if cookies.start_with?("{") && cookies.include?("=>")
          cleaned = cookies.gsub("=>", ":").gsub("nil", "null")
          begin
            JSON.parse(cleaned)
          rescue
            Rails.logger.error "Failed to parse cleaned cookies: #{cleaned}"
            {}
          end
        else
          {}
        end
      end
    else
      cookies
    end
  end
end
