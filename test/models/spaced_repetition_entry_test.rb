require "test_helper"

class SpacedRepetitionEntryTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @submission = submissions(:one)
    @entry = SpacedRepetitionEntry.create_from_submission(@user, @submission)
  end

  test "should create entry from submission" do
    assert @entry.persisted?
    assert_equal @submission.title, @entry.problem_title
    assert_equal @submission.title.parameterize, @entry.problem_slug
    assert_equal @submission.leetcode_id, @entry.leetcode_id
    assert_equal @submission.submitted_at, @entry.first_solved_at
    assert_equal 0, @entry.review_count
    assert_equal 2.5, @entry.ease_factor
    assert_equal 1, @entry.interval_days
    assert_not @entry.mastered
  end

  test "should not create entry for non-accepted submission" do
    @submission.update(status: "Wrong Answer")
    entry = SpacedRepetitionEntry.create_from_submission(@user, @submission)
    assert_nil entry
  end

  test "should not create duplicate entries" do
    entry2 = SpacedRepetitionEntry.create_from_submission(@user, @submission)
    assert_equal @entry.id, entry2.id
    assert_equal 1, SpacedRepetitionEntry.where(user: @user, problem_slug: @entry.problem_slug).count
  end

  test "should determine difficulty correctly" do
    # Test easy problem
    easy_submission = @submission.dup
    easy_submission.title = "Two Sum Easy"
    easy_entry = SpacedRepetitionEntry.create_from_submission(@user, easy_submission)
    assert_equal 1, easy_entry.difficulty_level

    # Test hard problem
    hard_submission = @submission.dup
    hard_submission.title = "Complex Hard Problem"
    hard_entry = SpacedRepetitionEntry.create_from_submission(@user, hard_submission)
    assert_equal 3, hard_entry.difficulty_level

    # Test medium problem (default)
    medium_submission = @submission.dup
    medium_submission.title = "Regular Problem"
    medium_entry = SpacedRepetitionEntry.create_from_submission(@user, medium_submission)
    assert_equal 2, medium_entry.difficulty_level
  end

  test "should calculate next review time based on difficulty" do
    # Easy problems get 1 day
    easy_entry = SpacedRepetitionEntry.new(difficulty_level: 1)
    next_review = SpacedRepetitionEntry.send(:calculate_next_review_time, 1)
    assert_equal 1.day.from_now.to_i, next_review.to_i

    # Medium problems get 2 days
    medium_entry = SpacedRepetitionEntry.new(difficulty_level: 2)
    next_review = SpacedRepetitionEntry.send(:calculate_next_review_time, 2)
    assert_equal 2.days.from_now.to_i, next_review.to_i

    # Hard problems get 3 days
    hard_entry = SpacedRepetitionEntry.new(difficulty_level: 3)
    next_review = SpacedRepetitionEntry.send(:calculate_next_review_time, 3)
    assert_equal 3.days.from_now.to_i, next_review.to_i
  end

  test "should handle review with score 1 (could not solve)" do
    @entry.review!(1)

    assert_equal 1, @entry.review_count
    assert_equal 1, @entry.interval_days
    assert_equal 2.3, @entry.ease_factor
    assert_not @entry.mastered
    assert_equal 1.day.from_now.to_i, @entry.next_review_at.to_i
  end

  test "should handle review with score 2 (solved with major hints)" do
    @entry.review!(2)

    assert_equal 1, @entry.review_count
    assert_equal 1, @entry.interval_days
    assert_equal 2.3, @entry.ease_factor
    assert_not @entry.mastered
  end

  test "should handle review with score 3 (solved with minor hints)" do
    @entry.review!(3)

    assert_equal 1, @entry.review_count
    assert_equal 1, @entry.interval_days
    assert_equal 2.5, @entry.ease_factor
    assert_not @entry.mastered
  end

  test "should handle review with score 4 (solved independently)" do
    @entry.review!(4)

    assert_equal 1, @entry.review_count
    assert_equal 1, @entry.interval_days # 1 * 1.3 = 1 (rounded down)
    assert_equal 2.5, @entry.ease_factor # 2.5 + 0.1 = 2.5 (capped)
    assert_not @entry.mastered
  end

  test "should handle review with score 5 (solved easily)" do
    @entry.review!(5)

    assert_equal 1, @entry.review_count
    assert_equal 1, @entry.interval_days # 1 * 1.3 = 1 (rounded down)
    assert_equal 2.5, @entry.ease_factor # 2.5 + 0.1 = 2.5 (capped)
    assert_not @entry.mastered
  end

  test "should increase intervals with good performance" do
    # Set up entry with longer interval
    @entry.update(interval_days: 10)

    @entry.review!(4)
    assert_equal 13, @entry.interval_days # 10 * 1.3 = 13
    assert_equal 2.5, @entry.ease_factor
    assert_equal 1, @entry.review_count
  end

  test "should cap interval at 365 days" do
    @entry.update(interval_days: 300)

    @entry.review!(5)
    assert_equal 365, @entry.interval_days # Capped at 365
    assert_equal 1, @entry.review_count
  end

  test "should cap ease factor at 2.5" do
    @entry.update(ease_factor: 2.4)

    @entry.review!(4)
    assert_equal 2.5, @entry.ease_factor # Capped at 2.5
    assert_equal 1, @entry.review_count
  end

  test "should not go below ease factor of 1.3" do
    @entry.update(ease_factor: 1.4)

    @entry.review!(1)
    assert_equal 1.3, @entry.ease_factor # Minimum is 1.3
    assert_equal 1, @entry.review_count
  end

  test "should mark as mastered after 6 successful reviews with long intervals" do
    # Set up entry with long interval
    @entry.update(interval_days: 30, review_count: 5)

    @entry.review!(4)
    assert @entry.mastered
    assert_equal 6, @entry.review_count
  end

  test "should not mark as mastered without long intervals" do
    @entry.update(interval_days: 5, review_count: 5)

    @entry.review!(4)
    assert_not @entry.mastered
    assert_equal 6, @entry.review_count
  end

  test "should not mark as mastered without enough reviews" do
    @entry.update(interval_days: 30, review_count: 3)

    @entry.review!(4)
    assert_not @entry.mastered
    assert_equal 4, @entry.review_count
  end

  test "should not review if already mastered" do
    @entry.update(mastered: true, review_count: 5)

    @entry.review!(4)
    assert_equal 5, @entry.review_count # Should not increment
  end

  test "should calculate days until review correctly" do
    @entry.update(next_review_at: 3.days.from_now)
    assert_equal 3, @entry.days_until_review
  end

  test "should return 0 for days until review if next_review_at is nil" do
    @entry.update(next_review_at: nil)
    assert_equal 0, @entry.days_until_review
  end

  test "should calculate overdue days correctly" do
    @entry.update(next_review_at: 2.days.ago)
    # Allow for some variance in time calculations
    assert @entry.overdue_days >= 1
    assert @entry.overdue_days <= 3
  end

  test "should return 0 for overdue days if not overdue" do
    @entry.update(next_review_at: 1.day.from_now)
    assert_equal 0, @entry.overdue_days
  end

  test "should calculate priority score correctly" do
    @entry.update(difficulty_level: 2, next_review_at: 1.day.ago)
    base_score = 2 * 10
    overdue_penalty = @entry.overdue_days * 5
    expected_score = base_score + overdue_penalty

    assert_equal expected_score, @entry.priority_score
  end

  test "should return correct difficulty name" do
    @entry.update(difficulty_level: 1)
    assert_equal "Easy", @entry.difficulty_name

    @entry.update(difficulty_level: 2)
    assert_equal "Medium", @entry.difficulty_name

    @entry.update(difficulty_level: 3)
    assert_equal "Hard", @entry.difficulty_name
  end

  test "should scope due for review correctly" do
    @entry.update(next_review_at: 1.day.ago)

    # Create a different entry manually to avoid find_or_create_by issues
    due_entry = SpacedRepetitionEntry.create!(
      user: @user,
      problem_title: "Different Problem",
      problem_slug: "different-problem",
      leetcode_id: "different_id",
      first_solved_at: Time.current,
      next_review_at: 1.day.from_now
    )

    due_entries = SpacedRepetitionEntry.due_for_review
    assert_includes due_entries, @entry
    assert_not_includes due_entries, due_entry
  end

  test "should scope not mastered correctly" do
    @entry.update(mastered: false)

    # Create a different entry manually
    mastered_entry = SpacedRepetitionEntry.create!(
      user: @user,
      problem_title: "Mastered Problem",
      problem_slug: "mastered-problem",
      leetcode_id: "mastered_id",
      first_solved_at: Time.current,
      mastered: true
    )

    not_mastered = SpacedRepetitionEntry.not_mastered
    assert_includes not_mastered, @entry
    assert_not_includes not_mastered, mastered_entry
  end

  test "should scope by difficulty correctly" do
    @entry.update(difficulty_level: 2)

    # Create a different entry manually
    easy_entry = SpacedRepetitionEntry.create!(
      user: @user,
      problem_title: "Easy Problem",
      problem_slug: "easy-problem",
      leetcode_id: "easy_id",
      first_solved_at: Time.current,
      difficulty_level: 1
    )

    medium_entries = SpacedRepetitionEntry.by_difficulty(2)
    assert_includes medium_entries, @entry
    assert_not_includes medium_entries, easy_entry
  end

  test "should validate required fields" do
    entry = SpacedRepetitionEntry.new
    assert_not entry.valid?
    assert_includes entry.errors[:problem_title], "can't be blank"
    assert_includes entry.errors[:problem_slug], "can't be blank"
    assert_includes entry.errors[:leetcode_id], "can't be blank"
    assert_includes entry.errors[:first_solved_at], "can't be blank"
  end

  test "should validate uniqueness of problem_slug per user" do
    entry2 = SpacedRepetitionEntry.new(
      user: @user,
      problem_slug: @entry.problem_slug,
      problem_title: "Different Title",
      leetcode_id: "different_id",
      first_solved_at: Time.current
    )

    assert_not entry2.valid?
    assert_includes entry2.errors[:problem_slug], "has already been taken"
  end
end
