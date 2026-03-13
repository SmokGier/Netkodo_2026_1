class ApplicationController < ActionController::API
  before_action :authenticate_user!
  
  private
  
  def authenticate_user!
    @current_user = find_current_user
    
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
  
  def current_user
    @current_user ||= find_current_user
  end
  
  def find_current_user
    # ✅ SZUKAJ PO API TOKENIE Z NAGŁÓWKA
    token = request.headers['X-Authorization'] || params[:token]
    return User.find_by(api_token: token) if token
    
    # ✅ SZUKAJ PO SESJI
    return User.find_by(id: session[:user_id]) if session[:user_id]
    
    nil
  end
end
