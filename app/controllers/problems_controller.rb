class ProblemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user

    if @user.leetcode_cookies.nil?
      redirect_to dashboard_path, alert: "Please link your LeetCode account first"
      return
    end

    cookies = parse_cookies(@user.leetcode_cookies)

    if cookies.empty?
      redirect_to dashboard_path, alert: "Unable to parse LeetCode cookies. Please re-link your account."
      return
    end

    @leetcode_service = LeetcodeService.new(cookies)
    @solved_problems = @leetcode_service.fetch_solved_problems || []
  end

  private

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
