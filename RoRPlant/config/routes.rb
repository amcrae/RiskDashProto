Rails.application.routes.draw do
  get 'plant/index'
  get 'plant/start_synth'
  get 'plant/stop_synth'
  
  resources :measurements
  resources :m_locations
  resources :segment_connections
  resources :segments
  resources :assets
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "plant#index"
end
