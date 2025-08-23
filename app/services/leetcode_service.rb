class LeetcodeService
  include HTTParty
  
  base_uri 'https://leetcode.com'
  
  def initialize(cookies = {})
    @cookies = cookies
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept' => 'application/json, text/plain, */*',
      'Accept-Language' => 'en-US,en;q=0.9',
      'Cookie' => cookies_to_string
    }
  end
  
  def validate_cookies
    Rails.logger.info "Validating LeetCode cookies: #{@cookies.inspect}"
    response = get('/api/problems/all/')
    Rails.logger.info "LeetCode validation response: #{response.code} - #{response.success?}"
    response.success? && response.code == 200
  rescue => e
    Rails.logger.error "Error validating LeetCode cookies: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    false
  end
  
  def fetch_user_profile
    response = get('/api/user/status/')
    if response.success?
      data = response.parsed_response
      Rails.logger.info "User status response: #{data.inspect}"
      
      return {
        username: data['userStatus']['username'],
        solved_count: data['userStatus']['numSolved'],
        total_count: data['userStatus']['numTotal'],
        rank: data['userStatus']['ranking']
      }
    end
    
    response = get('/api/problems/all/')
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
      
      username = data['user_name']
      solved_count = data['num_solved'].to_i
      total_count = data['num_total'].to_i
      
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
    response = get('/api/submissions/')
    return [] unless response.success?
    
    submissions = response.parsed_response['submissions_dump'] || []
    Rails.logger.info "Fetched #{submissions.length} submissions"
    
    submissions.first(10).map do |submission|
      {
        id: submission['id'],
        title: submission['title'],
        status: submission['status_display'],
        language: submission['lang'],
        timestamp: submission['timestamp'],
        url: "https://leetcode.com/problems/#{submission['title_slug']}"
      }
    end
  rescue => e
    Rails.logger.error "Error fetching LeetCode submissions: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    []
  end

  def calculate_total_active_days
    submissions = fetch_recent_submissions
    return 0 if submissions.empty?
    
    unique_dates = submissions.map do |submission|
      Time.at(submission[:timestamp]).to_date
    end.uniq
    
    unique_dates.count
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
    @cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
  end
  
  def get(path)
    Rails.logger.info "Making request to: #{path}"
    response = self.class.get(path, headers: @headers)
    Rails.logger.info "Response status: #{response.code}, success: #{response.success?}"
    Rails.logger.info "Response body preview: #{response.body[0..200]}..." if response.body
    response
  end
end
