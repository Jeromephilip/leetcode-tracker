require "test_helper"

class SpacedRepetitionServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @service = SpacedRepetitionService.new(@user)

    # Clear any existing entries and submissions to start fresh
    SpacedRepetitionEntry.delete_all
    Submission.delete_all

    # Create some test submissions (these are for tests that need existing entries)
    @submission1 = Submission.create!(
      user: @user,
      leetcode_id: "12345",
      title: "Two Sum",
      title_slug: "two-sum",
      status: "Accepted",
      language: "Python",
      timestamp: 1.day.ago.to_i,
      url: "https://leetcode.com/problems/two-sum/",
      code: "def twoSum(nums, target): pass",
      submitted_at: 1.day.ago
    )

    @submission2 = Submission.create!(
      user: @user,
      leetcode_id: "12346",
      title: "Add Two Numbers",
      title_slug: "add-two-numbers",
      status: "Accepted",
      language: "Java",
      timestamp: 2.days.ago.to_i,
      url: "https://leetcode.com/problems/add-two-numbers/",
      code: "public ListNode addTwoNumbers(ListNode l1, ListNode l2) { return null; }",
      submitted_at: 2.days.ago
    )

    @submission3 = Submission.create!(
      user: @user,
      leetcode_id: "12347",
      title: "Longest Substring",
      title_slug: "longest-substring",
      status: "Accepted",
      language: "Python",
      timestamp: 3.days.ago.to_i,
      url: "https://leetcode.com/problems/longest-substring/",
      code: "def lengthOfLongestSubstring(s): return 0",
      submitted_at: 3.days.ago
    )

    # Create some test entries (only for tests that need them)
    @entry1 = SpacedRepetitionEntry.create_from_submission(@user, @submission1)
    @entry2 = SpacedRepetitionEntry.create_from_submission(@user, @submission2)
    @entry3 = SpacedRepetitionEntry.create_from_submission(@user, @submission3)
  end

  test "should initialize with user" do
    service = SpacedRepetitionService.new(@user)
    assert_equal @user, service.instance_variable_get(:@user)
  end

  test "should return today's review tasks" do
    # Make entry1 due for review
    @entry1.update(next_review_at: 1.day.ago)
    # Make entry2 due for review
    @entry2.update(next_review_at: Time.current)
    # Make entry3 not due
    @entry3.update(next_review_at: 1.day.from_now)

    tasks = @service.todays_review_tasks

    assert_includes tasks, @entry1
    assert_includes tasks, @entry2
    assert_not_includes tasks, @entry3
  end

  test "should limit today's review tasks" do
    # Create more entries and make them all due
    (1..15).each do |i|
      submission = @submission1.dup
      submission.title = "Problem #{i}"
      submission.leetcode_id = "id_#{i}"
      entry = SpacedRepetitionEntry.create_from_submission(@user, submission)
      entry.update(next_review_at: 1.day.ago)
    end

    tasks = @service.todays_review_tasks(5)
    assert_equal 5, tasks.count
  end

  test "should not include mastered entries in today's tasks" do
    @entry1.update(next_review_at: 1.day.ago, mastered: true)
    @entry2.update(next_review_at: 1.day.ago, mastered: false)

    tasks = @service.todays_review_tasks

    assert_not_includes tasks, @entry1
    assert_includes tasks, @entry2
  end

  # Note: Entry creation tests moved to spaced_repetition_service_isolated_test.rb

  test "should calculate review stats correctly" do
    # Set up entries with different states
    @entry1.update(mastered: true)
    @entry2.update(next_review_at: 1.day.ago, mastered: false)
    @entry3.update(next_review_at: 1.day.from_now, mastered: false)

    stats = @service.review_stats

    assert_equal 3, stats[:total_problems]
    assert_equal 1, stats[:mastered]
    assert_equal 1, stats[:due_today]
    assert_equal 1, stats[:overdue]
    assert_equal 33.3, stats[:mastery_rate]
  end

  test "should handle zero total problems in stats" do
    SpacedRepetitionEntry.delete_all

    stats = @service.review_stats

    assert_equal 0, stats[:total_problems]
    assert_equal 0, stats[:mastered]
    assert_equal 0, stats[:due_today]
    assert_equal 0, stats[:overdue]
    assert_equal 0, stats[:mastery_rate]
  end

  # Note: Sync tests moved to spaced_repetition_service_isolated_test.rb

  test "should order today's tasks by next_review_at" do
    # Set different review times
    @entry1.update(next_review_at: 2.days.ago)
    @entry2.update(next_review_at: 1.day.ago)
    @entry3.update(next_review_at: Time.current)

    tasks = @service.todays_review_tasks

    # Should be ordered by next_review_at ASC (earliest first)
    assert_equal @entry1, tasks.first
    assert_equal @entry2, tasks.second
    assert_equal @entry3, tasks.third
  end

  test "should handle entries with nil next_review_at" do
    @entry1.update(next_review_at: nil)

    tasks = @service.todays_review_tasks

    # Entries with nil next_review_at should not be included
    assert_not_includes tasks, @entry1
  end

  test "should handle large numbers of entries efficiently" do
    # Create many entries
    (1..100).each do |i|
      submission = @submission1.dup
      submission.title = "Problem #{i}"
      submission.leetcode_id = "id_#{i}"
      entry = SpacedRepetitionEntry.create_from_submission(@user, submission)
      entry.update(next_review_at: i.days.ago)
    end

    # Should not raise an error and should limit results
    tasks = @service.todays_review_tasks(10)
    assert_equal 10, tasks.count
  end

  test "should calculate mastery rate with precision" do
    # Create 3 entries, master 1
    @entry1.update(mastered: true)
    @entry2.update(mastered: false)
    @entry3.update(mastered: false)

    stats = @service.review_stats

    # 1/3 = 33.333... should round to 33.3
    assert_equal 33.3, stats[:mastery_rate]
  end

  test "should handle edge case of all entries mastered" do
    @entry1.update(mastered: true)
    @entry2.update(mastered: true)
    @entry3.update(mastered: true)

    stats = @service.review_stats

    assert_equal 3, stats[:total_problems]
    assert_equal 3, stats[:mastered]
    assert_equal 0, stats[:due_today]
    assert_equal 0, stats[:overdue]
    assert_equal 100.0, stats[:mastery_rate]
  end
end
