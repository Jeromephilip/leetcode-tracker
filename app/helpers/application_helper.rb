module ApplicationHelper
  def format_submission_time(time)
    # Convert to user's local timezone (browser will handle conversion)
    # Store as UTC but display in a consistent format
    time.utc.strftime("%B %-d, %Y at %-I:%M %p UTC")
  end
end
