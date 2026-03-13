class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :destroy]
  
  def create
    user = User.find_by(username: params[:username])
    
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      
      # ✅ KLUCZOWA ZMIANA: COOKIE Z PATH='/'
      
      user.update(api_token: SecureRandom.hex(32)) if user.api_token.blank?
      
      render json: {
        success: true,
        user: {
          id: user.id,
          username: user.username,
          is_admin: user.role == 'admin',
          public_key: user.public_key,
          api_token: user.api_token
        }
      }
    else
      render json: { success: false, error: 'Nieprawidłowa nazwa użytkownika lub hasło' }, status: :unauthorized
    end
  end
  
  def destroy
    session[:user_id] = nil
    render json: { success: true }
  end
end
