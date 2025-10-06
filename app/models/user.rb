class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :submissions, dependent: :destroy

  validates :leetcode_username, uniqueness: { scope: :id, allow_blank: true }
  validate :leetcode_username_not_already_taken, if: :leetcode_username_changed?

  def leetcode_username_not_already_taken
    return if leetcode_username.blank?

    existing_user = User.where(leetcode_username: leetcode_username).where.not(id: id).first
    if existing_user
      errors.add(:leetcode_username, "is already linked to another account (#{existing_user.email})")
    end
  end

  def self.leetcode_username_available?(username)
    return false if username.blank?
    !where(leetcode_username: username).exists?
  end

  def self.find_by_leetcode_username(username)
    where(leetcode_username: username).first
  end

  # Session management methods
  def session_needs_refresh?
    return true if leetcode_last_sync.nil?
    leetcode_last_sync < calculate_refresh_interval.ago
  end

  def calculate_refresh_interval
    # Base refresh intervals based on user activity
    base_intervals = {
      active: 4.hours,      # Active users (updated in last 7 days)
      weekly: 12.hours,     # Weekly users (updated in last 30 days)
      monthly: 1.day,       # Monthly users (updated in last 90 days)
      inactive: 1.week      # Inactive users (90+ days)
    }

    activity_level = determine_activity_level
    base_interval = base_intervals[activity_level]

    # Adjust based on failure history
    if has_expired_sessions?
      # User has had expired sessions before, refresh more frequently
      base_interval = base_interval / 2
    end

    base_interval
  end

  def determine_activity_level
    last_active = updated_at

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

  def has_expired_sessions?
    # Check if user has had session issues before
    leetcode_last_sync.nil? || leetcode_last_sync < 1.day.ago
  end

  def schedule_session_refresh(force: false)
    return unless leetcode_cookies.present?

    if force || session_needs_refresh?
      LeetcodeSessionRefreshJob.perform_later(id)
      Rails.logger.info "Scheduled session refresh for user #{id}"
    end
  end

  def leetcode_session_healthy?
    return false unless leetcode_cookies.present?

    cookies = parse_leetcode_cookies
    return false if cookies.empty?

    leetcode_service = LeetcodeService.new(cookies)
    leetcode_service.session_healthy?
  rescue => e
    Rails.logger.error "Error checking session health for user #{id}: #{e.message}"
    false
  end

  private

  def parse_leetcode_cookies
    return {} if leetcode_cookies.blank?

    if leetcode_cookies.is_a?(String)
      JSON.parse(leetcode_cookies)
    else
      leetcode_cookies
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse LeetCode cookies for user #{id}: #{e.message}"
    {}
  end
end
