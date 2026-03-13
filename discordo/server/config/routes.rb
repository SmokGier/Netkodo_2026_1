Rails.application.routes.draw do
  # ✅ GŁÓWNY ROUTE DLA APLIKACJI
  get '/discordo', to: 'discordo#index'
  
  # ✅ RESZTA API
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  resources :users, only: [:create, :update]
  resources :chat_servers, only: [:index, :create, :show] do
    post :join, on: :member
  end
  resources :messages, only: [:index, :create, :destroy] do
    resources :reactions, only: [:create, :destroy]
  end
  get '/direct_messages/users', to: 'direct_messages#users'
  get '/direct_messages/:user_id', to: 'direct_messages#index'
  post '/direct_messages', to: 'direct_messages#create'
  delete '/direct_messages/:id', to: 'direct_messages#destroy'
  mount ActionCable.server => '/cable'
end
