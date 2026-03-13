class UserChannel < ApplicationCable::Channel
  def subscribed
    user_id = session[:user_id]
    if user_id
      stream_from "user_channel_#{user_id}"
    else
      reject
    end
  end

  def unsubscribed
    # Cleanup
  end
end
