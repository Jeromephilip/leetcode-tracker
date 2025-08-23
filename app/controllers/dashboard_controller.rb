class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @user = current_user
    
    if @user.leetcode_cookies.nil?
      render :link_account
      return
    end
    
    cookies = parse_cookies(@user.leetcode_cookies)
    
    if cookies.empty?
      @error = "Unable to parse LeetCode cookies. Please re-link your account."
      @leetcode_service = nil
      @recent_submissions = []
      @leetcode_profile = nil
    else
      @leetcode_service = LeetcodeService.new(cookies)
      
      @leetcode_profile = @leetcode_service.fetch_user_profile
      if @leetcode_profile
        @user.update(
          leetcode_solved_count: @leetcode_profile[:solved_count],
          leetcode_total_count: @leetcode_profile[:total_active_days],
          leetcode_rank: @leetcode_profile[:rank],
          leetcode_last_sync: Time.current
        )
      end
      
      @recent_submissions = @leetcode_service.fetch_recent_submissions
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
        
        if cookies.start_with?('{') && cookies.include?('=>')
          cleaned = cookies.gsub('=>', ':').gsub('nil', 'null')
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
