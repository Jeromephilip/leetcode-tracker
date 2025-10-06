class LeetcodeSessionRefreshSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting LeetCode session refresh scheduler"

    # Find users who need session refresh
    users_to_refresh = find_users_needing_refresh

    Rails.logger.info "Found #{users_to_refresh.count} users needing session refresh"

    users_to_refresh.find_each do |user|
      # Schedule refresh based on user activity level
      refresh_interval = calculate_refresh_interval(user)

      LeetcodeSessionRefreshJob.set(wait: refresh_interval).perform_later(user.id)
      Rails.logger.debug "Scheduled refresh for user #{user.id} in #{refresh_interval} seconds"
    end

    Rails.logger.info "Scheduled session refresh jobs for #{users_to_refresh.count} users"
  end

  private

  def find_users_needing_refresh
    User.where.not(leetcode_cookies: nil).where(
      # Only refresh sessions that haven't been synced recently
      leetcode_last_sync: ..6.hours.ago
    )
  end

  def calculate_refresh_interval(user)
    # Base refresh intervals based on user activity
    base_intervals = {
      active: 4.hours,      # Active users (updated in last 7 days)
      weekly: 12.hours,     # Weekly users (updated in last 30 days)
      monthly: 1.day,       # Monthly users (updated in last 90 days)
      inactive: 1.week      # Inactive users (90+ days)
    }

    # Determine user activity level
    activity_level = determine_activity_level(user)
    base_interval = base_intervals[activity_level]

    # Adjust based on failure history
    if user_has_expired_sessions?(user)
      # User has had expired sessions before, refresh more frequently
      base_interval = base_interval / 2
    end

    Rails.logger.debug "User #{user.id} activity: #{activity_level}, interval: #{base_interval}"
    base_interval
  end

  def determine_activity_level(user)
    last_active = user.updated_at

    if last_active > 7.days.ago
      :active
    elsif last_active > 30.days.ago
      :weekly
    elsif last_active > 90.days.ago
      :monthly
    else
      :inactive
    end
  end

  def user_has_expired_sessions?(user)
    # Check if user has had session issues before
    # This could be tracked in a separate field or inferred from patterns
    user.leetcode_last_sync.nil? || user.leetcode_last_sync < 1.day.ago
  end
end
