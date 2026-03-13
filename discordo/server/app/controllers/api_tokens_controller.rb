class ApiTokensController < ApplicationController
  before_action :authenticate_user
  
  def show
    if current_user.api_token
      render json: { api_token: current_user.api_token }
    else
      current_user.generate_api_token
      current_user.save!
      render json: { api_token: current_user.api_token }
    end
  end
  
  private
  
  def authenticate_user
    unless session[:user_id]
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    @current_user = User.find(session[:user_id])
  end
  
  def current_user
    @current_user
  end
end
