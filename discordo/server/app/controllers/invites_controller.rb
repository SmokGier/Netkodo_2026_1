class InvitesController < ApplicationController
  
  # POST /chat_servers/:chat_server_id/invites
  def create
    server = ChatServer.find(params[:chat_server_id])
    invite = server.invites.new(invite_params)
    invite.creator_id = session[:user_id] if session[:user_id]
    
    if invite.save
      render json: {
        code: invite.code,
        url: "#{request.protocol}#{request.host_with_port}/invite/#{invite.code}"
      }, status: :created
    else
      render json: { errors: invite.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # GET /chat_servers/:chat_server_id/invites/:code
  def show
    invite = Invite.find_by(code: params[:id])
    
    if invite && invite.valid?
      render json: {
        server_id: invite.chat_server_id,
        server_name: invite.chat_server.name,
        expires_at: invite.expires_at,
        uses_left: invite.uses_left
      }
    else
      render json: { error: 'Invalid or expired invite' }, status: :not_found
    end
  end
  
  private
  
  def invite_params
    params.require(:invite).permit(:expires_at, :uses_left)
  end
end
