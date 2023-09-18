Rails.application.routes.draw do
  get 'synth/restart_synth'
  get 'synth/stop_synth'
  get 'plant/index'
  
  resources :measurements
  resources :m_locations
  resources :segment_connections
  resources :segments
  resources :assets
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "plant#index"
end
