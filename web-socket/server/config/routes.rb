Rails.application.routes.draw do
  resources :tasks, only: [:index, :create, :update, :destroy]
  mount ActionCable.server => '/cable'
end
