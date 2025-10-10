require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not allow duplicate leetcode usernames" do
    user1 = User.create!(
      email: "user1@example.com",
      password: "password123",
      leetcode_username: "leetcode_user1"
    )

    user2 = User.new(
      email: "user2@example.com",
      password: "password123",
      leetcode_username: "leetcode_user1"
    )

    assert_not user2.valid?
    assert_includes user2.errors[:leetcode_username], "is already linked to another account (user1@example.com)"
  end

  test "should allow same user to update their leetcode username" do
    user = User.create!(
      email: "user@example.com",
      password: "password123",
      leetcode_username: "old_username"
    )

    user.leetcode_username = "new_username"
    assert user.valid?
  end

  test "leetcode_username_available? should return false for taken usernames" do
    User.create!(
      email: "user@example.com",
      password: "password123",
      leetcode_username: "taken_username"
    )

    assert_not User.leetcode_username_available?("taken_username")
    assert User.leetcode_username_available?("available_username")
  end

  test "solved count updates when submissions are created" do
    user = User.create!(
      email: "solved_count_test@example.com",
      password: "password123"
    )

    # Initially no solved count
    assert_nil user.leetcode_solved_count

    # Create an accepted submission
    submission1 = Submission.create!(
      user: user,
      leetcode_id: "1",
      title: "Two Sum",
      title_slug: "two-sum",
      status: "Accepted",
      language: "python",
      timestamp: Time.current.to_i,
      url: "https://leetcode.com/problems/two-sum",
      submitted_at: Time.current
    )

    user.reload
    assert_equal 1, user.leetcode_solved_count

    # Create another accepted submission for different problem
    submission2 = Submission.create!(
      user: user,
      leetcode_id: "2",
      title: "Add Two Numbers",
      title_slug: "add-two-numbers",
      status: "Accepted",
      language: "python",
      timestamp: Time.current.to_i,
      url: "https://leetcode.com/problems/add-two-numbers",
      submitted_at: Time.current
    )

    user.reload
    assert_equal 2, user.leetcode_solved_count

    # Create a rejected submission - should not affect count
    submission3 = Submission.create!(
      user: user,
      leetcode_id: "3",
      title: "Longest Substring",
      title_slug: "longest-substring",
      status: "Wrong Answer",
      language: "python",
      timestamp: Time.current.to_i,
      url: "https://leetcode.com/problems/longest-substring",
      submitted_at: Time.current
    )

    user.reload
    assert_equal 2, user.leetcode_solved_count

    # Create another accepted submission for same problem - should not increase count
    submission4 = Submission.create!(
      user: user,
      leetcode_id: "4",
      title: "Two Sum",
      title_slug: "two-sum",
      status: "Accepted",
      language: "java",
      timestamp: Time.current.to_i,
      url: "https://leetcode.com/problems/two-sum",
      submitted_at: Time.current
    )

    user.reload
    assert_equal 2, user.leetcode_solved_count
  end
end
