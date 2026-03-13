class ChatServersController < ApplicationController
  
  def index
    servers = ChatServer.all.map do |server|
      {
        id: server.id,
        name: server.name,
        private: server.private?,
        owner_id: server.owner_id
      }
    end
    render json: servers
  end
  
  def create
    server = ChatServer.new(name: chat_server_params[:name])
    server.owner_id = current_user.id
    
    if chat_server_params[:password].present?
      server.password_digest = BCrypt::Password.create(chat_server_params[:password])
    end
    
    if server.save
      session["joined_server_#{server.id}"] = true
      render json: {
        id: server.id,
        name: server.name,
        private: server.private?,
        owner_id: server.owner_id
      }, status: :created
    else
      render json: { errors: server.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def join
    server = ChatServer.find(params[:id])
    
    password = params[:password]
    
    unless server.correct_password?(password || '')
      render json: { error: 'Nieprawidłowe hasło' }, status: :unauthorized
      return
    end
    
    session["joined_server_#{server.id}"] = true
    
    render json: {
      id: server.id,
      name: server.name,
      private: server.private?,
      owner_id: server.owner_id
    }
  end
  
  private
  
  def chat_server_params
    params.require(:chat_server).permit(:name, :password, :password_confirmation)
  end
end
