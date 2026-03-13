class TypingController < ApplicationController
  
  # POST /typing
  def create
    server_id = params[:chat_server_id]
    channel_id = params[:channel_id]
    user_id = session[:user_id]
    username = current_username
    is_typing = params[:is_typing] == 'true'
    
    if user_id && server_id
      # Broadcast typing status
      channel_name = server_id ? "chat_channel_#{server_id}" : "chat_channel_general"
      ActionCable.server.broadcast(
        channel_name,
        {
          action: "typing",
          user_id: user_id,
          username: username,
          is_typing: is_typing,
          channel_id: channel_id
        }
      )
      
      render json: { success: true }
    else
      render json: { error: 'Invalid server or unauthorized' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def current_username
    user = User.find(session[:user_id]) if session[:user_id]
    user&.username || 'Anonymous'
  end
end
