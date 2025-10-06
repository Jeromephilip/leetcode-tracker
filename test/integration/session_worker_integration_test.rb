require "test_helper"

class SessionWorkerIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @user.update(
      leetcode_cookies: { "LEETCODE_SESSION" => "test_session" }.to_json,
      leetcode_username: "testuser",
      leetcode_last_sync: 2.hours.ago
    )
    sign_in @user
  end

  test "refresh_session endpoint schedules job" do
    assert_enqueued_with(job: LeetcodeSessionRefreshJob, args: [ @user.id, { force_refresh: true } ]) do
      post "/api/v1/leetcode/refresh_session"
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "Session refresh initiated. Please check back in a few minutes.", json_response["message"]
  end

  test "refresh_session endpoint returns error for user without cookies" do
    @user.update(leetcode_cookies: nil)

    post "/api/v1/leetcode/refresh_session"

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "No LeetCode account linked", json_response["error"]
  end

  test "session_health endpoint returns health status" do
    LeetcodeService.any_instance.stubs(:session_healthy?).returns(true)

    get "/api/v1/leetcode/session_health"

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["healthy"]
    assert_equal "testuser", json_response["leetcode_username"]
    assert json_response["activity_level"]
    assert json_response["refresh_interval"]
  end

  test "session_health endpoint returns unhealthy status" do
    LeetcodeService.any_instance.stubs(:session_healthy?).returns(false)

    get "/api/v1/leetcode/session_health"

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not json_response["healthy"]
  end

  test "session_health endpoint returns error for user without cookies" do
    @user.update(leetcode_cookies: nil)

    get "/api/v1/leetcode/session_health"

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not json_response["healthy"]
    assert_equal "No LeetCode account linked", json_response["message"]
  end

  test "endpoints require authentication" do
    sign_out @user

    post "/api/v1/leetcode/refresh_session"
    assert_response :unauthorized

    get "/api/v1/leetcode/session_health"
    assert_response :unauthorized
  end
end
