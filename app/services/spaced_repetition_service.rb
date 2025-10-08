class SpacedRepetitionService
  def initialize(user)
    @user = user
  end

  def todays_review_tasks(limit = 10)
    @user.spaced_repetition_entries
         .due_for_review
         .not_mastered
         .order(:next_review_at)
         .limit(limit)
  end

  def create_entries_from_recent_submissions
    recent_submissions = @user.submissions
                             .accepted
                             .where("submitted_at > ?", 30.days.ago)

    created_count = 0
    recent_submissions.each do |submission|
      existing_entry = @user.spaced_repetition_entries.find_by(problem_slug: submission.title.parameterize)

      unless existing_entry
        entry = SpacedRepetitionEntry.create_from_submission(@user, submission)
        created_count += 1 if entry&.persisted?
      end
    end

    created_count
  end

  def review_stats
    total_entries = @user.spaced_repetition_entries.count
    mastered_count = @user.spaced_repetition_entries.where(mastered: true).count
    due_count = todays_review_tasks.count
    overdue_count = @user.spaced_repetition_entries
                         .where("next_review_at < ?", Time.current)
                         .where(mastered: false)
                         .count

    {
      total_problems: total_entries,
      mastered: mastered_count,
      due_today: due_count,
      overdue: overdue_count,
      mastery_rate: total_entries > 0 ? (mastered_count.to_f / total_entries * 100).round(1) : 0
    }
  end

  def sync_with_submissions
    # Create entries for all accepted submissions that don't have entries yet
    accepted_submissions = @user.submissions.accepted

    created_count = 0
    accepted_submissions.each do |submission|
      existing_entry = @user.spaced_repetition_entries.find_by(problem_slug: submission.title.parameterize)

      unless existing_entry
        entry = SpacedRepetitionEntry.create_from_submission(@user, submission)
        created_count += 1 if entry&.persisted?
      end
    end

    created_count
  end
end
