Rails.application.routes.draw do
  resources :measurements
  resources :m_locations
  resources :segment_connections
  resources :segments
  resources :assets
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
