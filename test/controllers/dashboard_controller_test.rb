require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to sign in when not authenticated" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end
end
