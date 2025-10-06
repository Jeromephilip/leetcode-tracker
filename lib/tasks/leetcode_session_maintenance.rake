namespace :leetcode do
  desc "Refresh LeetCode sessions for active users"
  task refresh_sessions: :environment do
    Rails.logger.info "Starting LeetCode session refresh task"

    # Find users who need session refresh
    users_to_refresh = User.where.not(leetcode_cookies: nil).where(
      # Only refresh sessions that haven't been synced recently
      leetcode_last_sync: [ nil, ...6.hours.ago ]
    )

    Rails.logger.info "Found #{users_to_refresh.count} users needing session refresh"

    if users_to_refresh.count == 0
      puts "No users need session refresh at this time."
      exit 0
    end

    users_to_refresh.find_each do |user|
      LeetcodeSessionRefreshJob.perform_later(user.id)
      puts "Scheduled refresh for user #{user.id} (#{user.leetcode_username})"
    end

    Rails.logger.info "Scheduled session refresh jobs for #{users_to_refresh.count} users"
    puts "Scheduled #{users_to_refresh.count} session refresh jobs"
  end

  desc "Refresh LeetCode session for a specific user"
  task :refresh_user_session, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id]

    if user_id.blank?
      puts "Please provide a user ID: rake leetcode:refresh_user_session[123]"
      exit 1
    end

    user = User.find_by(id: user_id)
    if user.nil?
      puts "User with ID #{user_id} not found"
      exit 1
    end

    if user.leetcode_cookies.blank?
      puts "User #{user_id} (#{user.email}) has no LeetCode cookies"
      exit 1
    end

    puts "Refreshing session for user #{user_id} (#{user.email})"
    LeetcodeSessionRefreshJob.perform_later(user.id)
    puts "Session refresh job scheduled for user #{user_id}"
  end

  desc "Check LeetCode session health for all users"
  task check_session_health: :environment do
    Rails.logger.info "Starting LeetCode session health check"

    users_with_cookies = User.where.not(leetcode_cookies: nil)

    puts "Checking session health for #{users_with_cookies.count} users..."

    healthy_count = 0
    expired_count = 0
    error_count = 0

    users_with_cookies.find_each do |user|
      begin
        if user.leetcode_session_healthy?
          healthy_count += 1
          puts "User #{user.id} (#{user.leetcode_username}): Healthy"
        else
          expired_count += 1
          puts "User #{user.id} (#{user.leetcode_username}): Expired"
        end
      rescue => e
        error_count += 1
        puts "User #{user.id} (#{user.leetcode_username}): Error - #{e.message}"
      end
    end

    puts "\nSession Health Summary:"
    puts "  Healthy: #{healthy_count}"
    puts "  Expired: #{expired_count}"
    puts "  Errors: #{error_count}"
    puts "  Total: #{users_with_cookies.count}"
  end

  desc "Schedule periodic session refresh for all users"
  task schedule_periodic_refresh: :environment do
    Rails.logger.info "Scheduling periodic LeetCode session refresh"

    LeetcodeSessionRefreshSchedulerJob.perform_later

    puts "Periodic session refresh scheduler job enqueued"
  end

  desc "Force refresh all LeetCode sessions (ignores timing restrictions)"
  task force_refresh_all: :environment do
    Rails.logger.info "Starting forced LeetCode session refresh"

    users_with_cookies = User.where.not(leetcode_cookies: nil)

    Rails.logger.info "Found #{users_with_cookies.count} users with LeetCode cookies"

    if users_with_cookies.count == 0
      puts "No users have LeetCode cookies to refresh."
      exit 0
    end

    users_with_cookies.find_each do |user|
      LeetcodeSessionRefreshJob.perform_later(user.id, force_refresh: true)
      puts "Force scheduled refresh for user #{user.id} (#{user.leetcode_username})"
    end

    Rails.logger.info "Force scheduled session refresh jobs for #{users_with_cookies.count} users"
    puts "Force scheduled #{users_with_cookies.count} session refresh jobs"
  end
end
