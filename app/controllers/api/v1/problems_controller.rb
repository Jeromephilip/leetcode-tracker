class Api::V1::ProblemsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [ :notes ]

  def notes
    problem_id = params[:problem_id]
    problem_title = params[:problem_title]
    notes = params[:notes]

    if problem_id.blank? || problem_title.blank?
      render json: { success: false, error: "Missing required parameters" }, status: :bad_request
      return
    end

    begin
      # Parse existing notes from JSON string or initialize empty hash
      user_notes = if current_user.leetcode_notes.present?
        begin
          JSON.parse(current_user.leetcode_notes)
        rescue JSON::ParserError
          {}
        end
      else
        {}
      end

      # Add/update the problem notes
      user_notes[problem_id] = {
        "title" => problem_title,
        "notes" => notes,
        "updated_at" => Time.current.iso8601
      }

      # Store the notes as JSON string
      current_user.update(leetcode_notes: user_notes.to_json)

      render json: {
        success: true,
        message: "Notes saved successfully",
        notes: notes
      }
    rescue => e
      Rails.logger.error "Error saving notes: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
      render json: { success: false, error: "Failed to save notes" }, status: :internal_server_error
    end
  end

  private

  def notes_params
    params.permit(:problem_id, :problem_title, :notes)
  end
end
