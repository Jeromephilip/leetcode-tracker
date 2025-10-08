class Api::V1::SpacedRepetitionController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def review
    entry = current_user.spaced_repetition_entries.find(params[:entry_id])
    quality_score = params[:quality_score].to_i

    if quality_score.between?(1, 5)
      entry.review!(quality_score)
      render json: {
        success: true,
        next_review_at: entry.next_review_at,
        mastered: entry.mastered,
        interval_days: entry.interval_days,
        review_count: entry.review_count
      }
    else
      render json: { success: false, error: "Invalid quality score" }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "Review entry not found" }, status: :not_found
  rescue => e
    Rails.logger.error "Error in spaced repetition review: #{e.message}"
    render json: { success: false, error: "Failed to process review" }, status: :internal_server_error
  end

  def stats
    service = SpacedRepetitionService.new(current_user)
    render json: { success: true, stats: service.review_stats }
  end

  def sync
    service = SpacedRepetitionService.new(current_user)
    created_count = service.sync_with_submissions

    render json: {
      success: true,
      message: "Synced #{created_count} new problems for spaced repetition",
      created_count: created_count
    }
  end
end
