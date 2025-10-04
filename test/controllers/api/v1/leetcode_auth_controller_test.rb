require "test_helper"

class Api::V1::LeetcodeAuthControllerTest < ActionDispatch::IntegrationTest
  test "should check username availability for available username" do
    get "/api/v1/leetcode/check_username/available_user"

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal "available_user", json_response["username"]
    assert json_response["available"]
    assert_nil json_response["existing_user"]
  end

  test "should check username availability for taken username" do
    User.create!(
      email: "other@example.com",
      password: "password123",
      leetcode_username: "taken_user"
    )

    get "/api/v1/leetcode/check_username/taken_user"

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal "taken_user", json_response["username"]
    assert_not json_response["available"]
    assert_not_nil json_response["existing_user"]
    assert_equal "other@example.com", json_response["existing_user"]["email"]
  end

  test "should return error for whitespace-only username" do
    get "/api/v1/leetcode/check_username/%20%20%20"

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "Username cannot be empty or contain only whitespace", json_response["error"]
  end
end
