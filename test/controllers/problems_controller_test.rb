require "test_helper"

class ProblemsControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication" do
    get problems_path
    assert_redirected_to new_user_session_path
  end
end
