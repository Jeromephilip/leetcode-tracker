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
end
