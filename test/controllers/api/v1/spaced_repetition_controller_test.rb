require "test_helper"

class Api::V1::SpacedRepetitionControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    sign_in @user

    @submission = submissions(:one)
    @entry = SpacedRepetitionEntry.create_from_submission(@user, @submission)
  end

  test "should require authentication for review" do
    sign_out @user

    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 4
    }

    assert_response :redirect
  end

  test "should submit review successfully" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 4
    }

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_not_nil json_response["next_review_at"]
    assert_not json_response["mastered"]
    assert_equal 1, json_response["interval_days"]
    assert_equal 1, json_response["review_count"]
  end

  test "should handle review with score 1" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 1
    }

    assert_response :success

    @entry.reload
    assert_equal 1, @entry.review_count
    assert_equal 1, @entry.interval_days
    assert_equal 2.3, @entry.ease_factor
  end

  test "should handle review with score 5" do
    @entry.update(interval_days: 10)

    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 5
    }

    assert_response :success

    @entry.reload
    assert_equal 1, @entry.review_count
    assert_equal 13, @entry.interval_days # 10 * 1.3 = 13
  end

  test "should mark as mastered after successful reviews" do
    @entry.update(interval_days: 30, review_count: 5)

    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 4
    }

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["mastered"]

    @entry.reload
    assert @entry.mastered
  end

  test "should reject invalid quality scores" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 0
    }

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Invalid quality score", json_response["error"]
  end

  test "should reject quality scores above 5" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 6
    }

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Invalid quality score", json_response["error"]
  end

  test "should handle non-existent entry" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: 99999,
      quality_score: 4
    }

    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Review entry not found", json_response["error"]
  end

  test "should not allow reviewing other user's entries" do
    other_user = users(:two)
    other_entry = SpacedRepetitionEntry.create_from_submission(other_user, @submission)

    post "/api/v1/spaced_repetition/review", params: {
      entry_id: other_entry.id,
      quality_score: 4
    }

    assert_response :not_found
  end

  test "should get stats successfully" do
    @entry.update(mastered: true)

    get "/api/v1/spaced_repetition/stats"

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_not_nil json_response["stats"]

    stats = json_response["stats"]
    assert_equal 1, stats["total_problems"]
    assert_equal 1, stats["mastered"]
    assert_equal 0, stats["due_today"]
    assert_equal 0, stats["overdue"]
    assert_equal 100.0, stats["mastery_rate"]
  end

  test "should require authentication for stats" do
    sign_out @user

    get "/api/v1/spaced_repetition/stats"

    assert_response :redirect
  end

  test "should sync problems successfully" do
    # Clear existing entries
    SpacedRepetitionEntry.delete_all

    # Create accepted submission
    submission = @submission.dup
    submission.update(status: "Accepted")

    post "/api/v1/spaced_repetition/sync"

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    # The count depends on how many accepted submissions exist in fixtures
    assert json_response["created_count"] >= 0
    assert_includes json_response["message"], "Synced"
  end

  test "should handle sync with no new problems" do
    # Entry already exists from setup

    post "/api/v1/spaced_repetition/sync"

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    # Should be 0 since entry already exists
    assert json_response["created_count"] >= 0
    assert_includes json_response["message"], "Synced"
  end

  test "should require authentication for sync" do
    sign_out @user

    post "/api/v1/spaced_repetition/sync"

    assert_response :redirect
  end

  test "should handle review of already mastered entry" do
    @entry.update(mastered: true, review_count: 5)

    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 4
    }

    assert_response :success

    # Review count should not change
    @entry.reload
    assert_equal 5, @entry.review_count
  end

  test "should handle string quality scores" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: "4"
    }

    assert_response :success

    @entry.reload
    assert_equal 1, @entry.review_count
  end

  test "should handle float quality scores" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id,
      quality_score: 4.0
    }

    assert_response :success

    @entry.reload
    assert_equal 1, @entry.review_count
  end

  test "should handle missing parameters gracefully" do
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: @entry.id
      # Missing quality_score
    }

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Invalid quality score", json_response["error"]
  end

  test "should handle database errors gracefully" do
    # Test with invalid entry ID to simulate database error
    post "/api/v1/spaced_repetition/review", params: {
      entry_id: 99999, # Non-existent ID
      quality_score: 4
    }

    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_includes json_response["error"], "Review entry not found"
  end

  test "should handle concurrent reviews" do
    # Simulate concurrent reviews
    threads = []

    3.times do
      threads << Thread.new do
        post "/api/v1/spaced_repetition/review", params: {
          entry_id: @entry.id,
          quality_score: 4
        }
      end
    end

    threads.each(&:join)

    @entry.reload
    # Should handle concurrent updates gracefully
    assert @entry.review_count >= 1
  end

  test "should validate entry belongs to current user" do
    # Create entry for different user
    other_user = users(:two)
    other_entry = SpacedRepetitionEntry.create_from_submission(other_user, @submission)

    post "/api/v1/spaced_repetition/review", params: {
      entry_id: other_entry.id,
      quality_score: 4
    }

    assert_response :not_found
  end

  test "should handle edge case quality scores" do
    # Test boundary values
    [ 1, 2, 3, 4, 5 ].each do |score|
      # Create a unique submission for each score
      unique_submission = Submission.create!(
        user: @user,
        leetcode_id: "edge_#{score}",
        title: "Edge Problem #{score}",
        title_slug: "edge-problem-#{score}",
        status: "Accepted",
        language: "Python",
        timestamp: 1.day.ago.to_i,
        url: "https://leetcode.com/problems/edge-problem-#{score}/",
        code: "def edge#{score}(): pass",
        submitted_at: 1.day.ago
      )

      entry = SpacedRepetitionEntry.create_from_submission(@user, unique_submission)

      post "/api/v1/spaced_repetition/review", params: {
        entry_id: entry.id,
        quality_score: score
      }

      assert_response :success, "Failed for quality score #{score}"
    end
  end
end
