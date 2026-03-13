class DirectMessageChannel < ApplicationCable::Channel
  def subscribed
    stream_from "dm_channel_#{params[:user_id]}"
  end
end
