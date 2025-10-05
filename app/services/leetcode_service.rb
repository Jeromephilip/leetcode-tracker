class LeetcodeService
  include HTTParty

  base_uri "https://leetcode.com"

  def initialize(cookies = {})
    @cookies = cookies
    Rails.logger.info "Initializing LeetcodeService with cookies: #{cookies.inspect}"
    @headers = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
      "Accept" => "application/json, text/plain, */*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cookie" => cookies_to_string
    }
    Rails.logger.info "Headers: #{@headers.inspect}"
  end

  def validate_cookies
    Rails.logger.info "Validating LeetCode cookies: #{@cookies.inspect}"
    response = get("/api/problems/all/")
    Rails.logger.info "LeetCode validation response: #{response.code} - #{response.success?}"
    response.success? && response.code == 200
  rescue => e
    Rails.logger.error "Error validating LeetCode cookies: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    false
  end

  def fetch_user_profile
    response = get("/api/user/status/")
    if response.success?
      data = response.parsed_response
      Rails.logger.info "User status response: #{data.inspect}"

      return {
        username: data["userStatus"]["username"],
        solved_count: data["userStatus"]["numSolved"],
        total_count: data["userStatus"]["numTotal"],
        rank: data["userStatus"]["ranking"]
      }
    end

    response = get("/api/problems/all/")
    if response.success?
      data = if response.parsed_response.is_a?(String)
               JSON.parse(response.parsed_response)
      else
               response.parsed_response
      end

      Rails.logger.info "Problems endpoint response: #{data.inspect}"
      Rails.logger.info "Response keys: #{data.keys}"
      Rails.logger.info "Raw num_solved: #{data['num_solved']} (class: #{data['num_solved'].class})"
      Rails.logger.info "Raw num_total: #{data['num_total']} (class: #{data['num_total'].class})"

      Rails.logger.info "Trying alternative keys:"
      Rails.logger.info "data['num_solved']: #{data['num_solved']}"
      Rails.logger.info "data[:num_solved]: #{data[:num_solved]}"
      Rails.logger.info "data['solved']: #{data['solved']}"
      Rails.logger.info "data['problems_solved']: #{data['problems_solved']}"

      username = data["user_name"]
      solved_count = data["num_solved"].to_i
      total_count = data["num_total"].to_i

      total_active_days = calculate_total_active_days

      Rails.logger.info "Converted solved_count: #{solved_count}, total_active_days: #{total_active_days}"

      rank = calculate_rank(solved_count, total_count)

      return {
        username: username,
        solved_count: solved_count,
        total_active_days: total_active_days,
        rank: rank
      }
    end

    Rails.logger.error "Could not fetch user profile from any endpoint"
    nil
  rescue => e
    Rails.logger.error "Error fetching LeetCode profile: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    nil
  end

  def fetch_recent_submissions
    # Add a small delay to avoid rate limiting
    sleep(0.5) if @last_request_time && (Time.current - @last_request_time) < 1.0

    response = get("/api/submissions/")
    @last_request_time = Time.current

    # Handle 403 Forbidden - session expired or rate limited
    if response.code == 403
      Rails.logger.warn "LeetCode submissions API returned 403 - session may be expired or rate limited"
      return []
    end

    return [] unless response.success?

    submissions = response.parsed_response["submissions_dump"] || []
    Rails.logger.info "Fetched #{submissions.length} submissions"

    submissions.first(10).map do |submission|
      # Handle different possible data structures
      title = submission["title"] || submission["question__title"] || "Unknown"
      title_slug = submission["title_slug"] || submission["question__title_slug"] || title.parameterize

      {
        id: submission["id"],
        title: title,
        title_slug: title_slug,
        status: submission["status_display"] || submission["status"] || "Unknown",
        language: submission["lang"] || submission["language"] || "Unknown",
        timestamp: submission["timestamp"],
        url: "https://leetcode.com/problems/#{title_slug}",
        code: submission["code"]
      }
    end
  rescue => e
    Rails.logger.error "Error fetching LeetCode submissions: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    []
  end

  def fetch_solved_problems
    problems_response = get("/api/problems/all/")

    Rails.logger.info "Problems response: #{problems_response.code} - #{problems_response.success?}"

    return [] unless problems_response.success?
    problems_data = problems_response.parsed_response
    if problems_data.is_a?(String)
      begin
        problems_data = JSON.parse(problems_data)
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse problems response as JSON: #{e.message}"
        problems_data = {}
      end
    end

    problems = problems_data["stat_status_pairs"] || []

    Rails.logger.info "Problems response type: #{problems_data.class}, keys: #{problems_data.keys if problems_data.is_a?(Hash)}"
    Rails.logger.info "Problems response preview: #{problems_data.inspect[0..200]}..." if problems_data
    Rails.logger.info "Fetched #{problems.length} problems"

    solved_problems = problems
      .select { |problem| problem["status"] == "ac" } # "ac" means accepted/solved
      .map do |problem|
        stat = problem["stat"]
        difficulty = problem["difficulty"]["level"]

                  {
            title: stat["question__title"],
            title_slug: stat["question__title_slug"],
            difficulty: case difficulty
                        when 1 then "Easy"
                        when 2 then "Medium"
                        when 3 then "Hard"
                        else "Unknown"
                        end,
            status: "Solved",
            url: "https://leetcode.com/problems/#{stat['question__title_slug']}",
            notes: "",
            algorithms: detect_algorithms(stat["question__title"], stat["question__title_slug"])
          }
      end

    Rails.logger.info "Found #{solved_problems.length} solved problems"
    solved_problems
  rescue => e
    Rails.logger.error "Error fetching solved problems: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    []
  end

  private

  def detect_algorithms(title, title_slug)
    algorithms = []

    # Convert to lowercase for easier matching
    title_lower = title.downcase
    slug_lower = title_slug.downcase

    # Graph algorithms
    if title_lower.include?("graph") || title_lower.include?("tree") || title_lower.include?("node") ||
       slug_lower.include?("graph") || slug_lower.include?("tree") || slug_lower.include?("node") ||
       title_lower.include?("bfs") || title_lower.include?("dfs") || title_lower.include?("traversal")
      algorithms << "Graph/Tree"
    end

    # Dynamic Programming
    if title_lower.include?("dp") || title_lower.include?("dynamic") || title_lower.include?("memoization") ||
       title_lower.include?("subsequence") || title_lower.include?("substring") || title_lower.include?("palindrome") ||
       title_lower.include?("coin") || title_lower.include?("knapsack") || title_lower.include?("climbing")
      algorithms << "Dynamic Programming"
    end

    # Two Pointers
    if title_lower.include?("two pointer") || title_lower.include?("2 pointer") || title_lower.include?("fast slow") ||
       title_lower.include?("slow fast") || title_lower.include?("hare tortoise") || title_lower.include?("cycle") ||
       title_lower.include?("linked list") || title_lower.include?("array") && (title_lower.include?("sum") || title_lower.include?("target")) ||
       title_lower.include?("palindrome") && title_lower.include?("string") || title_lower.include?("reverse") && title_lower.include?("list")
      algorithms << "Two Pointers"
    end

    # Binary Search
    if title_lower.include?("binary search") || title_lower.include?("search") && (title_lower.include?("sorted") || title_lower.include?("array")) ||
       slug_lower.include?("search") || title_lower.include?("median") || title_lower.include?("kth")
      algorithms << "Binary Search"
    end

    # Sliding Window
    if title_lower.include?("sliding window") || title_lower.include?("window") || title_lower.include?("subarray") ||
       title_lower.include?("substring") || title_lower.include?("consecutive") || title_lower.include?("k")
      algorithms << "Sliding Window"
    end

    # Stack/Queue
    if title_lower.include?("stack") || title_lower.include?("queue") || title_lower.include?("monotonic") ||
       title_lower.include?("bracket") || title_lower.include?("parentheses") || title_lower.include?("valid")
      algorithms << "Stack/Queue"
    end

    # Greedy
    if title_lower.include?("greedy") || title_lower.include?("minimum") || title_lower.include?("maximum") ||
       title_lower.include?("optimal") || title_lower.include?("schedule") || title_lower.include?("meeting")
      algorithms << "Greedy"
    end

    # Backtracking
    if title_lower.include?("backtrack") || title_lower.include?("combination") || title_lower.include?("permutation") ||
       title_lower.include?("n-queens") || title_lower.include?("sudoku") || title_lower.include?("generate")
      algorithms << "Backtracking"
    end

    # Hash Table
    if title_lower.include?("hash") || title_lower.include?("frequency") || title_lower.include?("count") ||
       title_lower.include?("duplicate") || title_lower.include?("unique") || title_lower.include?("anagram") ||
       title_lower.include?("two sum") || title_lower.include?("3sum") || title_lower.include?("4sum") ||
       title_lower.include?("group") || title_lower.include?("mapping")
      algorithms << "Hash Table"
    end

    # Sort
    if title_lower.include?("sort") || title_lower.include?("merge") || title_lower.include?("quick") ||
       title_lower.include?("bubble") || title_lower.include?("insertion") || title_lower.include?("selection")
      algorithms << "Sort"
    end

    # Math
    if title_lower.include?("math") || title_lower.include?("prime") || title_lower.include?("factorial") ||
       title_lower.include?("gcd") || title_lower.include?("lcm") || title_lower.include?("modulo") ||
       title_lower.include?("power") || title_lower.include?("square") || title_lower.include?("root")
      algorithms << "Math"
    end

    # Bit Manipulation
    if title_lower.include?("bit") || title_lower.include?("xor") || title_lower.include?("and") ||
       title_lower.include?("or") || title_lower.include?("shift") || title_lower.include?("power of 2")
      algorithms << "Bit Manipulation"
    end

    # If no specific algorithms detected, add a general category
    algorithms << "General" if algorithms.empty?

    algorithms
  end



  def calculate_total_active_days
    Rails.logger.info "Skipping submissions fetch in calculate_total_active_days to avoid rate limiting"
    0
  end

  def calculate_rank(solved_count, total_count)
    return 0 if solved_count.nil? || total_count.nil? || total_count == 0

    percentage = (solved_count.to_f / total_count) * 100

    case percentage
    when 90..100
      1
    when 80..89
      2
    when 70..79
      3
    when 60..69
      4
    when 50..59
      5
    when 40..49
      6
    when 30..39
      7
    when 20..29
      8
    when 10..19
      9
    else
      10
    end
  end

  private

  def cookies_to_string
    cookie_string = @cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
    Rails.logger.info "Cookie string: #{cookie_string}"
    cookie_string
  end

  def get(path)
    Rails.logger.info "Making request to: #{path}"
    response = self.class.get(path, headers: @headers)
    Rails.logger.info "Response status: #{response.code}, success: #{response.success?}"
    Rails.logger.info "Response body preview: #{response.body[0..200]}..." if response.body
    response
  end
end
