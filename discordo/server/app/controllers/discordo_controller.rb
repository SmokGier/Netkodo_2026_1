class DiscordoController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    # ✅ RENDERUJ PLIK HTML Z KATALOGU PUBLIC
    render file: Rails.root.join('public', 'discordo', 'index.html'), layout: false, content_type: 'text/html'
  end
end
