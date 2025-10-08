require "test_helper"

class SpacedRepetitionServiceIsolatedTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @service = SpacedRepetitionService.new(@user)
  end

  test "should create entries from recent submissions" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create recent accepted submission
    recent_submission = Submission.create!(
      user: @user,
      leetcode_id: "recent_id",
      title: "Recent Problem",
      title_slug: "recent-problem",
      status: "Accepted",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/recent-problem/",
      code: "def recent(): pass",
      submitted_at: 1.day.ago
    )

    created_count = @service.create_entries_from_recent_submissions

    assert_equal 1, created_count
    assert_equal 1, SpacedRepetitionEntry.count
  end

  test "should not create entries from old submissions" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create old accepted submission
    old_submission = Submission.create!(
      user: @user,
      leetcode_id: "old_id",
      title: "Old Problem",
      title_slug: "old-problem",
      status: "Accepted",
      language: "Python",
      timestamp: 35.days.ago.to_i,
      url: "https://leetcode.com/problems/old-problem/",
      code: "def old(): pass",
      submitted_at: 35.days.ago
    )

    created_count = @service.create_entries_from_recent_submissions

    assert_equal 0, created_count
    assert_equal 0, SpacedRepetitionEntry.count
  end

  test "should not create entries from non-accepted submissions" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create recent non-accepted submission
    recent_submission = Submission.create!(
      user: @user,
      leetcode_id: "wrong_id",
      title: "Wrong Problem",
      title_slug: "wrong-problem",
      status: "Wrong Answer",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/wrong-problem/",
      code: "def wrong(): pass",
      submitted_at: 1.day.ago
    )

    created_count = @service.create_entries_from_recent_submissions

    assert_equal 0, created_count
    assert_equal 0, SpacedRepetitionEntry.count
  end

  test "should not create duplicate entries" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create a submission
    submission = Submission.create!(
      user: @user,
      leetcode_id: "duplicate_id",
      title: "Duplicate Problem",
      title_slug: "duplicate-problem",
      status: "Accepted",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/duplicate-problem/",
      code: "def duplicate(): pass",
      submitted_at: 1.day.ago
    )

    # Create entry manually
    SpacedRepetitionEntry.create_from_submission(@user, submission)

    # Try to create again with same submission
    created_count = @service.create_entries_from_recent_submissions

    assert_equal 0, created_count
    assert_equal 1, SpacedRepetitionEntry.count
  end

  test "should sync with submissions" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create accepted submissions with unique titles
    submission1 = Submission.create!(
      user: @user,
      leetcode_id: "sync1",
      title: "Sync Problem 1",
      title_slug: "sync-problem-1",
      status: "Accepted",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/sync-problem-1/",
      code: "def sync1(): pass",
      submitted_at: 1.day.ago
    )

    submission2 = Submission.create!(
      user: @user,
      leetcode_id: "sync2",
      title: "Sync Problem 2",
      title_slug: "sync-problem-2",
      status: "Accepted",
      language: "Java",
      timestamp: 2.days.ago.to_i,
      url: "https://leetcode.com/problems/sync-problem-2/",
      code: "public void sync2() {}",
      submitted_at: 2.days.ago
    )

    created_count = @service.sync_with_submissions

    assert_equal 2, created_count
    assert_equal 2, SpacedRepetitionEntry.count
  end

  test "should not sync duplicate entries" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create a submission
    submission = Submission.create!(
      user: @user,
      leetcode_id: "duplicate_sync_id",
      title: "Duplicate Sync Problem",
      title_slug: "duplicate-sync-problem",
      status: "Accepted",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/duplicate-sync-problem/",
      code: "def duplicate_sync(): pass",
      submitted_at: 1.day.ago
    )

    # Create entry manually
    SpacedRepetitionEntry.create_from_submission(@user, submission)

    # Try to sync
    created_count = @service.sync_with_submissions

    assert_equal 0, created_count
    assert_equal 1, SpacedRepetitionEntry.count
  end

  test "should not sync non-accepted submissions" do
    # Clear everything
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create non-accepted submission
    submission = Submission.create!(
      user: @user,
      leetcode_id: "wrong_sync_id",
      title: "Wrong Sync Problem",
      title_slug: "wrong-sync-problem",
      status: "Wrong Answer",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/wrong-sync-problem/",
      code: "def wrong_sync(): pass",
      submitted_at: 1.day.ago
    )

    created_count = @service.sync_with_submissions

    assert_equal 0, created_count
    assert_equal 0, SpacedRepetitionEntry.count
  end
end
