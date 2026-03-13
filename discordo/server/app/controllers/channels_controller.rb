class ChannelsController < ApplicationController
  before_action :authenticate_user, only: [:create]
  
  # GET /chat_servers/:chat_server_id/channels
  def index
    server = ChatServer.find(params[:chat_server_id])
    channels = server.channels.ordered
    render json: channels
  end
  
  # POST /chat_servers/:chat_server_id/channels
  def create
    server = ChatServer.find(params[:chat_server_id])
    channel = server.channels.new(channel_params)
    
    if channel.save
      render json: channel, status: :created
    else
      render json: { errors: channel.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # GET /channels/:id
  def show
    channel = Channel.find(params[:id])
    render json: channel
  end
  
  # PATCH /channels/:id
  def update
    channel = Channel.find(params[:id])
    if channel.update(channel_params)
      render json: channel
    else
      render json: { errors: channel.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /channels/:id
  def destroy
    channel = Channel.find(params[:id])
    channel.destroy
    render json: { success: true }
  end
  
  private
  
  def channel_params
    params.require(:channel).permit(:name, :category, :position)
  end
  
  def authenticate_user
    unless session[:user_id]
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
