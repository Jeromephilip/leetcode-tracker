class LeetcodeSessionRefreshJob < ApplicationJob
  queue_as :default

  # Retry the job if it fails due to temporary issues
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Don't retry if the user no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, force_refresh: false)
    user = User.find(user_id)
    return unless user.leetcode_cookies.present?

    Rails.logger.info "Starting session refresh for user #{user.id} (#{user.leetcode_username})"

    cookies = parse_cookies(user.leetcode_cookies)
    leetcode_service = LeetcodeService.new(cookies)

    # Check if we should attempt refresh
    unless force_refresh || should_attempt_refresh?(user)
      Rails.logger.info "Skipping refresh for user #{user.id} - too soon since last refresh"
      return
    end

    # Try to refresh the session by making a lightweight API call
    if refresh_session(leetcode_service)
      Rails.logger.info "Session refresh successful for user #{user.id}"
      user.update(leetcode_last_sync: Time.current)

      # Optionally fetch fresh data while we have a working session
      fetch_and_update_user_data(user, leetcode_service)
    else
      Rails.logger.warn "Session refresh failed for user #{user.id} - cookies may be expired"
      # Could notify user or mark for manual re-linking
      handle_session_expired(user)
    end
  rescue => e
    Rails.logger.error "Error in session refresh for user #{user_id}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    raise e
  end

  private

  def parse_cookies(cookies)
    return {} if cookies.blank?

    if cookies.is_a?(String)
      JSON.parse(cookies)
    else
      cookies
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse cookies for user: #{e.message}"
    {}
  end

  def should_attempt_refresh?(user)
    return true if user.leetcode_last_sync.nil?

    # Don't refresh more than once per hour
    user.leetcode_last_sync < 1.hour.ago
  end

  def refresh_session(leetcode_service)
    # Try multiple lightweight endpoints to refresh the session
    refresh_endpoints = [
      "/api/user/status/",
      "/api/problems/all/"
    ]

    refresh_endpoints.each do |endpoint|
      begin
        response = leetcode_service.send(:get, endpoint)
        if response.success? && response.code == 200
          Rails.logger.info "Session refreshed using endpoint: #{endpoint}"
          return true
        end
      rescue => e
        Rails.logger.warn "Failed to refresh using #{endpoint}: #{e.message}"
        next
      end
    end

    false
  end

  def fetch_and_update_user_data(user, leetcode_service)
    # While we have a working session, update user stats
    profile = leetcode_service.fetch_user_profile
    if profile
      user.update(
        leetcode_solved_count: profile[:solved_count],
        leetcode_total_count: profile[:total_active_days],
        leetcode_rank: profile[:rank]
      )
      Rails.logger.info "Updated user stats for #{user.id}"
    end
  rescue => e
    Rails.logger.warn "Failed to update user data: #{e.message}"
  end

  def handle_session_expired(user)
    # You could implement various strategies here:
    # 1. Send email notification
    # 2. Mark user for manual re-linking
    # 3. Schedule another refresh attempt later
    # 4. Clear cookies to force re-linking

    Rails.logger.warn "Session expired for user #{user.id}, may need manual re-linking"

    # Example: Schedule another attempt in 1 hour
    LeetcodeSessionRefreshJob.set(wait: 1.hour).perform_later(user.id)
  end
end
