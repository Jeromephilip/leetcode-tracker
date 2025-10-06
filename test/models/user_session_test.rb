require "test_helper"

class UserSessionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.update(
      leetcode_cookies: { "LEETCODE_SESSION" => "test_session" }.to_json,
      leetcode_username: "testuser"
    )
  end

  test "session_needs_refresh returns true for new user" do
    @user.update(leetcode_last_sync: nil)
    assert @user.session_needs_refresh?
  end

  test "session_needs_refresh returns true when interval passed" do
    @user.update(leetcode_last_sync: 5.hours.ago, updated_at: 1.day.ago)
    assert @user.session_needs_refresh?
  end

  test "session_needs_refresh returns false when interval not passed" do
    @user.update(leetcode_last_sync: 1.hour.ago, updated_at: 1.day.ago)
    assert_not @user.session_needs_refresh?
  end

  test "calculate_refresh_interval for active user" do
    @user.update(updated_at: 1.day.ago)
    interval = @user.calculate_refresh_interval
    assert_equal 4.hours, interval
  end

  test "calculate_refresh_interval for weekly user" do
    @user.update(updated_at: 2.weeks.ago)
    interval = @user.calculate_refresh_interval
    assert_equal 12.hours, interval
  end

  test "calculate_refresh_interval for monthly user" do
    @user.update(updated_at: 2.months.ago)
    interval = @user.calculate_refresh_interval
    assert_equal 1.day, interval
  end

  test "calculate_refresh_interval for inactive user" do
    @user.update(updated_at: 6.months.ago)
    interval = @user.calculate_refresh_interval
    assert_equal 1.week, interval
  end

  test "determine_activity_level for active user" do
    @user.update(updated_at: 1.day.ago)
    assert_equal :active, @user.determine_activity_level
  end

  test "determine_activity_level for weekly user" do
    @user.update(updated_at: 2.weeks.ago)
    assert_equal :weekly, @user.determine_activity_level
  end

  test "determine_activity_level for monthly user" do
    @user.update(updated_at: 2.months.ago)
    assert_equal :monthly, @user.determine_activity_level
  end

  test "determine_activity_level for inactive user" do
    @user.update(updated_at: 6.months.ago)
    assert_equal :inactive, @user.determine_activity_level
  end

  test "has_expired_sessions returns true for user without sync" do
    @user.update(leetcode_last_sync: nil)
    assert @user.has_expired_sessions?
  end

  test "has_expired_sessions returns true for user with old sync" do
    @user.update(leetcode_last_sync: 2.days.ago)
    assert @user.has_expired_sessions?
  end

  test "has_expired_sessions returns false for user with recent sync" do
    @user.update(leetcode_last_sync: 12.hours.ago)
    assert_not @user.has_expired_sessions?
  end

  test "schedule_session_refresh enqueues job when needed" do
    @user.update(leetcode_last_sync: 5.hours.ago)

    assert_enqueued_with(job: LeetcodeSessionRefreshJob) do
      @user.schedule_session_refresh
    end
  end

  test "schedule_session_refresh does not enqueue when not needed" do
    @user.update(leetcode_last_sync: 1.hour.ago)

    assert_no_enqueued_jobs do
      @user.schedule_session_refresh
    end
  end

  test "schedule_session_refresh enqueues when forced" do
    @user.update(leetcode_last_sync: 1.hour.ago)

    assert_enqueued_with(job: LeetcodeSessionRefreshJob) do
      @user.schedule_session_refresh(force: true)
    end
  end

  test "leetcode_session_healthy returns false without cookies" do
    @user.update(leetcode_cookies: nil)
    assert_not @user.leetcode_session_healthy?
  end

  test "leetcode_session_healthy calls service method" do
    LeetcodeService.any_instance.stubs(:session_healthy?).returns(true)

    assert @user.leetcode_session_healthy?
  end
end
