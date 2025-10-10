class ProblemsService
  def initialize(user)
    @user = user
  end

  def fetch_solved_problems_with_notes
    return [] unless user_has_cookies?

    cookies = parse_cookies(@user.leetcode_cookies)
    return [] if cookies.empty?

    leetcode_service = LeetcodeService.new(cookies)
    solved_problems = leetcode_service.fetch_solved_problems || []

    merge_notes_with_problems(solved_problems)
  end

  def find_problem_by_slug(slug)
    solved_problems = fetch_solved_problems_with_notes
    solved_problems.find { |problem| problem[:id] == slug }
  end

  def parse_user_notes
    return {} unless @user.leetcode_notes.present?

    begin
      JSON.parse(@user.leetcode_notes)
    rescue JSON::ParserError
      Rails.logger.warn "Failed to parse user notes for user #{@user.id}"
      {}
    end
  end

  def merge_notes_with_problems(problems)
    user_notes = parse_user_notes

    problems.map do |problem|
      problem_id = problem[:title].parameterize

      if user_notes[problem_id]
        problem[:notes] = user_notes[problem_id]["notes"]
        problem[:id] = problem_id
      else
        problem[:notes] = ""
        problem[:id] = problem_id
      end

      problem
    end
  end

  def user_has_cookies?
    @user.leetcode_cookies.present?
  end

  def cookies_valid?
    return false unless user_has_cookies?

    cookies = parse_cookies(@user.leetcode_cookies)
    !cookies.empty?
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
