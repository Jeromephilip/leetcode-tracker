class SpacedRepetitionEntry < ApplicationRecord
  belongs_to :user

  validates :problem_title, :problem_slug, :leetcode_id, :first_solved_at, presence: true
  validates :problem_slug, uniqueness: { scope: :user_id }

  # Ebbinghaus-based intervals (in days)
  INTERVALS = [ 0, 1, 3, 7, 14, 30, 60, 120 ].freeze

  scope :due_for_review, -> { where("next_review_at <= ?", Time.current) }
  scope :not_mastered, -> { where(mastered: false) }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) }

  def self.create_from_submission(user, submission)
    return if submission.status != "Accepted"

    find_or_create_by(
      user: user,
      problem_slug: submission.title.parameterize
    ) do |entry|
      entry.problem_title = submission.title
      entry.leetcode_id = submission.leetcode_id
      entry.first_solved_at = submission.submitted_at
      entry.difficulty_level = determine_difficulty(submission)
      entry.next_review_at = calculate_next_review_time(entry.difficulty_level)
    end
  end

  def review!(quality_score)
    # Quality score: 1-5 (1=could not solve, 5=solved easily)
    return if mastered?

    self.review_count += 1
    self.last_reviewed_at = Time.current

    if quality_score >= 4
      # Good performance (solved independently or easily) - increase interval
      self.interval_days = [ interval_days * 1.3, 365 ].min.to_i
      self.ease_factor = [ ease_factor + 0.1, 2.5 ].min
    elsif quality_score == 3
      # Moderate performance (solved with minor hints) - maintain interval
      self.interval_days = interval_days
    else
      # Poor performance (could not solve or needed major hints) - reset to beginning
      self.interval_days = 1
      self.ease_factor = [ ease_factor - 0.2, 1.3 ].max
    end

    # Mark as mastered after 6 successful reviews (score 4-5) with long intervals
    if review_count >= 6 && interval_days >= 30
      self.mastered = true
    end

    self.next_review_at = interval_days.days.from_now
    save!
  end

  def days_until_review
    return 0 if next_review_at.nil?
    [ (next_review_at - Time.current) / 1.day, 0 ].max.ceil
  end

  def overdue_days
    return 0 if next_review_at.nil? || next_review_at > Time.current
    ((Time.current - next_review_at) / 1.day).ceil
  end

  def priority_score
    # Higher score = higher priority for review
    base_score = difficulty_level * 10
    overdue_penalty = overdue_days * 5
    base_score + overdue_penalty
  end

  def difficulty_name
    [ "Easy", "Medium", "Hard" ][difficulty_level - 1]
  end

  private

  def self.determine_difficulty(submission)
    # You can enhance this by fetching actual difficulty from LeetCode API
    # For now, use a simple heuristic based on problem title patterns
    title = submission.title.downcase
    if title.include?("easy") || title.include?("simple")
      1
    elsif title.include?("hard") || title.include?("complex")
      3
    else
      2
    end
  end

  def self.calculate_next_review_time(difficulty)
    # Initial intervals based on difficulty
    initial_intervals = { 1 => 1, 2 => 2, 3 => 3 }
    initial_intervals[difficulty].days.from_now
  end
end
