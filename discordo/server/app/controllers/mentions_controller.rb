class MentionsController < ApplicationController
  
  # POST /messages/:message_id/mentions
  def create
    message = Message.find(params[:message_id])
    mentioned_user = User.find_by(username: params[:mention][:username])
    
    if mentioned_user
      mention = message.mentions.new(
        mentioned_user_id: mentioned_user.id,
        user_id: session[:user_id]
      )
      
      if mention.save
        # Send desktop notification via Action Cable
        ActionCable.server.broadcast(
          "user_channel_#{mentioned_user.id}",
          {
            action: "mention",
            message: message.content,
            from: current_username,
            channel: message.channel&.name || 'general'
          }
        )
        render json: mention, status: :created
      else
        render json: { errors: mention.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end
  
  private
  
  def current_username
    user = User.find(session[:user_id]) if session[:user_id]
    user&.username || 'Anonymous'
  end
end
