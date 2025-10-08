class Submission < ApplicationRecord
  belongs_to :user

  validates :leetcode_id, presence: true, uniqueness: { scope: :user_id }
  validates :title, presence: true
  validates :title_slug, presence: true
  validates :status, presence: true
  validates :language, presence: true
  validates :timestamp, presence: true
  validates :url, presence: true
  validates :submitted_at, presence: true

  scope :recent, -> { order(submitted_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_language, ->(language) { where(language: language) }
  scope :accepted, -> { where(status: "Accepted") }
  scope :in_date_range, ->(start_date, end_date) { where(submitted_at: start_date..end_date) }

  def self.cache_key(user_id, limit = 10)
    "user:#{user_id}:submissions:recent:#{limit}"
  end

  def self.recent_for_user(user_id, limit = 10)
    cache_key = cache_key(user_id, limit)

    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      where(user_id: user_id)
        .recent
        .limit(limit)
        .to_a
    end
  end

  # Clear cache when submissions are updated
  def clear_user_cache
    Rails.cache.delete_matched("user:#{user_id}:submissions:*")
  end

  after_save :clear_user_cache
  after_destroy :clear_user_cache

  # Convert to hash format for API responses
  def to_api_hash
    {
      id: leetcode_id,
      title: title,
      status: status,
      language: language,
      timestamp: timestamp,
      url: url,
      submitted_at: submitted_at.iso8601
    }
  end

  def self.to_api_array(submissions)
    submissions.map(&:to_api_hash)
  end

  def self.sync_from_api(user, api_submissions)
    return [] if api_submissions.blank?

    synced_submissions = []

    api_submissions.each do |submission_data|
      submission = find_or_initialize_by(
        user: user,
        leetcode_id: submission_data[:id].to_s
      )

      attributes = {
        title: submission_data[:title],
        title_slug: submission_data[:title_slug] || submission_data[:title].parameterize,
        status: submission_data[:status],
        language: submission_data[:language],
        timestamp: submission_data[:timestamp],
        url: submission_data[:url],
        code: submission_data[:code]
      }

      if submission.new_record?
        attributes[:submitted_at] = Time.at(submission_data[:timestamp]).utc
      end

      submission.assign_attributes(attributes)

      if submission.save
        synced_submissions << submission
      else
        Rails.logger.warn "Failed to save submission #{submission_data[:id]}: #{submission.errors.full_messages.join(', ')}"
      end
    end

    Rails.cache.delete_matched("user:#{user.id}:submissions:*")

    synced_submissions
  end
end
