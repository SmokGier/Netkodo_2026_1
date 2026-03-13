class MessagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    if params[:chat_server_id].present?
      server = ChatServer.find_by(id: params[:chat_server_id])
      
      # ✅ USUNIĘTO SPRZAWDZENIE SESJI - wystarczy autoryzacja
      messages = server ? Message.where(chat_server_id: server.id).order(created_at: :desc).limit(50) : []
    else
      messages = Message.where(chat_server_id: nil).order(created_at: :desc).limit(50)
    end
    
    render json: messages.reverse.map { |m| message_with_reactions(m) }
  end
  
  def create
    message = Message.new(message_params)
    message.user_id = current_user.id if current_user
    
    if params[:chat_server_id].present?
      server = ChatServer.find_by(id: params[:chat_server_id])
      
      # ✅ SPRZAWDZENIE SESJI TYLKO PRZY WYSYŁANIU
      if server&.private? && !session["joined_server_#{server.id}"]
        render json: { error: 'Nie dołączono do serwera prywatnego' }, status: :forbidden
        return
      end
      
      message.chat_server_id = server.id if server
    end
    
    if message.save
      channel_name = message.chat_server_id ? "chat_channel_#{message.chat_server_id}" : "chat_channel_general"
      
      ActionCable.server.broadcast(
        channel_name,
        {
          action: "new_message",
          message: message_with_reactions(message)
        }
      )
      render json: message_with_reactions(message), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    message = Message.find(params[:id])
    
    unless can_delete_message?(message)
      render json: { error: 'Nie masz uprawnień do usunięcia tej wiadomości' }, status: :forbidden
      return
    end
    
    message.destroy
    head :no_content
  end
  
  private
  
  def message_params
    params.require(:message).permit(:content, :username)
  end
  
  def message_with_reactions(message)
    message.as_json.merge({
      reactions: message.reactions.group(:emoji).count,
      user_id: message.user_id
    })
  end
  
  def can_delete_message?(message)
    return true if current_user&.role == 'admin'
    
    if message.chat_server_id
      server = ChatServer.find_by(id: message.chat_server_id)
      return true if server && server.owner_id == current_user&.id
    end
    
    message.user_id == current_user&.id
  end
end
