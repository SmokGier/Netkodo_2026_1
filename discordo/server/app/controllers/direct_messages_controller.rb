class DirectMessagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:users]
  
  def users
    users = User.all.map do |user|
      {
        id: user.id,
        username: user.username,
        public_key: user.public_key || SecureRandom.hex(32)
      }
    end
    render json: users
  end
  
  def index
    # ✅ ZABEZPIECZENIE: jeśli current_user jest nil, zwróć pustą tablicę
    return render json: [] unless current_user
    
    other_user_id = params[:user_id].to_i
    
    messages = DirectMessage.where(
      "(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
      current_user.id, other_user_id,
      other_user_id, current_user.id
    ).order(created_at: :asc).limit(100)
    
    render json: messages.map { |m| {
      id: m.id,
      content: m.content,
      sender_id: m.sender_id,
      sender_username: m.sender.username,
      recipient_id: m.recipient_id,
      created_at: m.created_at.iso8601
    } }
  end
  
  def create
    # ✅ ZABEZPIECZENIE: jeśli current_user jest nil, zwróć błąd
    return render json: { error: 'Nie jesteś zalogowany' }, status: :unauthorized unless current_user
    
    recipient = User.find(params[:recipient_id])
    
    message = DirectMessage.new(
      sender_id: current_user.id,
      recipient_id: recipient.id,
      content: params[:content]
    )
    
    if message.save
      payload = {
        action: "new_dm",
        message: {
          id: message.id,
          content: message.content,
          sender_id: message.sender_id,
          sender_username: message.sender.username,
          recipient_id: message.recipient_id,
          created_at: message.created_at.iso8601
        }
      }
      
      ActionCable.server.broadcast("dm_channel_#{recipient.id}", payload)
      ActionCable.server.broadcast("dm_channel_#{current_user.id}", payload)
      
      render json: payload[:message], status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    # ✅ ZABEZPIECZENIE: jeśli current_user jest nil, zwróć błąd
    return render json: { error: 'Nie jesteś zalogowany' }, status: :unauthorized unless current_user
    
    message = DirectMessage.find(params[:id])
    
    # ✅ Tylko nadawca może usunąć wiadomość DM
    unless message.sender_id == current_user.id
      render json: { error: 'Możesz usunąć tylko swoje wiadomości' }, status: :forbidden
      return
    end
    
    message.destroy
    head :no_content
  end
end
