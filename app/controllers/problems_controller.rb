class ProblemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @problems_service = ProblemsService.new(@user)

    unless @problems_service.user_has_cookies?
      redirect_to dashboard_path, alert: "Please link your LeetCode account first"
      return
    end

    unless @problems_service.cookies_valid?
      redirect_to dashboard_path, alert: "Unable to parse LeetCode cookies. Please re-link your account."
      return
    end

    @solved_problems = @problems_service.fetch_solved_problems_with_notes
  end

  def show
    @user = current_user
    @problems_service = ProblemsService.new(@user)

    unless @problems_service.user_has_cookies?
      redirect_to dashboard_path, alert: "Please link your LeetCode account first"
      return
    end

    unless @problems_service.cookies_valid?
      redirect_to dashboard_path, alert: "Unable to parse LeetCode cookies. Please re-link your account."
      return
    end

    @problem = @problems_service.find_problem_by_slug(params[:id])

    if @problem.nil?
      redirect_to problems_path, alert: "Problem not found"
      nil
    end
  end
end
