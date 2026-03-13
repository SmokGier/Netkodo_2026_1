class PollChannel < ApplicationCable::Channel
  def subscribed
    poll_id = params[:poll_id]
    if poll_id
      stream_from "poll_channel_#{poll_id}"
    else
      reject
    end
  end

  def unsubscribed
    # Cleanup
  end
end
