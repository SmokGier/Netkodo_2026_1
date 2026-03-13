class ReactionsController < ApplicationController
  
  # POST /messages/:message_id/reactions
  # TOGGLE: jeśli reakcja istnieje → usuń, jeśli nie → dodaj
  # NASTĘPNIE: zwróć ZAKTUALIZOWANE reakcje dla wiadomości
  def create
    message = Message.find(params[:message_id])
    emoji = params[:reaction][:emoji]
    user_id = session[:user_id]
    
    if !user_id
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    
    # Sprawdź czy reakcja już istnieje
    existing = Reaction.find_by(
      message_id: message.id,
      user_id: user_id,
      emoji: emoji
    )
    
    if existing
      # USUŃ reakcję
      existing.destroy
    else
      # DODAJ reakcję
      reaction = message.reactions.new(emoji: emoji, user_id: user_id)
      reaction.save
    end
    
    # ZAKTUALIZUJ REAKCJE DLA WIADOMOŚCI I ZWROC
    updated_reactions = message.reactions.group(:emoji).count
    
    # Broadcast do WS
    channel_name = message.chat_server_id ? "chat_channel_#{message.chat_server_id}" : "chat_channel_general"
    ActionCable.server.broadcast(
      channel_name,
      {
        action: "update_reactions",
        message_id: message.id,
        reactions: updated_reactions
      }
    )
    
    render json: { success: true, reactions: updated_reactions }
  end
end
