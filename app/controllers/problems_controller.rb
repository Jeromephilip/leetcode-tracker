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

    # Add user notes to the problems
    user_notes = if @user.leetcode_notes.present?
      begin
        JSON.parse(@user.leetcode_notes)
      rescue JSON::ParserError
        {}
      end
    else
      {}
    end

    @solved_problems.each do |problem|
      problem_id = problem[:title].parameterize
      if user_notes[problem_id]
        problem[:notes] = user_notes[problem_id]["notes"]
        problem[:id] = problem_id
      else
        problem[:notes] = ""
        problem[:id] = problem_id
      end
    end
  end

  def show
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

    # Find the specific problem
    @problem = @solved_problems.find { |p| p[:title].parameterize == params[:id] }

    if @problem.nil?
      redirect_to problems_path, alert: "Problem not found"
      return
    end

    # Add user notes to the problem
    user_notes = if @user.leetcode_notes.present?
      begin
        JSON.parse(@user.leetcode_notes)
      rescue JSON::ParserError
        {}
      end
    else
      {}
    end

    problem_id = @problem[:title].parameterize
    if user_notes[problem_id]
      @problem[:notes] = user_notes[problem_id]["notes"]
      @problem[:id] = problem_id
    else
      @problem[:notes] = ""
      @problem[:id] = problem_id
    end
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
