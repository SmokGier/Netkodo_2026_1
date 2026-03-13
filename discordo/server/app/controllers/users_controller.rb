class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]
  
  def create
    user = User.new(user_params)
    
    if user.save
      user.update(api_token: SecureRandom.hex(32)) if user.api_token.blank?
      
      render json: {
        success: true,
        user: {
          id: user.id,
          username: user.username,
          public_key: user.public_key,
          api_token: user.api_token
        }
      }, status: :created
    else
      render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
end
