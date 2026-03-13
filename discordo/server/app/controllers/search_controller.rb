class SearchController < ApplicationController
  
  # GET /search?q=hello&server_id=1&channel_id=2&user=Maciej
  def index
    query = params[:q]
    server_id = params[:server_id]
    channel_id = params[:channel_id]
    username = params[:user]
    since = params[:since]
    
    messages = Message.all
    
    if query
      messages = messages.search(query)
    end
    
    if server_id
      messages = messages.where(chat_server_id: server_id)
    end
    
    if channel_id
      messages = messages.where(channel_id: channel_id)
    end
    
    if username
      messages = messages.by_user(username)
    end
    
    if since
      messages = messages.since(since)
    end
    
    messages = messages.recent(100)
    
    render json: messages
  end
end
