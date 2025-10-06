require "test_helper"

class LeetcodeSessionRefreshJobTest < ActiveJob::TestCase
  def setup
    @user = users(:one)
    @user.update(
      leetcode_cookies: { "LEETCODE_SESSION" => "test_session" }.to_json,
      leetcode_username: "testuser",
      leetcode_last_sync: 2.hours.ago
    )
  end

  test "performs session refresh successfully" do
    # Mock successful LeetCode service calls
    LeetcodeService.any_instance.stubs(:refresh_session).returns(true)
    LeetcodeService.any_instance.stubs(:fetch_user_profile).returns({
      solved_count: 10,
      total_active_days: 5,
      rank: 3
    })

    assert_enqueued_with(job: LeetcodeSessionRefreshJob) do
      LeetcodeSessionRefreshJob.perform_now(@user.id)
    end

    @user.reload
    assert_not_nil @user.leetcode_last_sync
  end

  test "skips refresh if too soon since last refresh" do
    @user.update(leetcode_last_sync: 30.minutes.ago)

    LeetcodeService.any_instance.expects(:refresh_session).never

    LeetcodeSessionRefreshJob.perform_now(@user.id)

    # Should not update last_sync
    @user.reload
    assert_equal 30.minutes.ago.to_i, @user.leetcode_last_sync.to_i
  end

  test "forces refresh when force_refresh is true" do
    @user.update(leetcode_last_sync: 30.minutes.ago)

    LeetcodeService.any_instance.stubs(:refresh_session).returns(true)
    LeetcodeService.any_instance.stubs(:fetch_user_profile).returns({
      solved_count: 10,
      total_active_days: 5,
      rank: 3
    })

    LeetcodeSessionRefreshJob.perform_now(@user.id, force_refresh: true)

    @user.reload
    assert_not_nil @user.leetcode_last_sync
  end

  test "handles expired session gracefully" do
    LeetcodeService.any_instance.stubs(:refresh_session).returns(false)

    assert_enqueued_with(job: LeetcodeSessionRefreshJob, at: 1.hour.from_now) do
      LeetcodeSessionRefreshJob.perform_now(@user.id)
    end
  end

  test "handles user without cookies" do
    @user.update(leetcode_cookies: nil)

    LeetcodeService.any_instance.expects(:refresh_session).never

    LeetcodeSessionRefreshJob.perform_now(@user.id)
  end

  test "handles non-existent user" do
    assert_raises(ActiveRecord::RecordNotFound) do
      LeetcodeSessionRefreshJob.perform_now(99999)
    end
  end
end
