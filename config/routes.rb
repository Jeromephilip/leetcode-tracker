Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes for LeetCode integration
  namespace :api do
    namespace :v1 do
      post 'leetcode/authenticate', to: 'leetcode_auth#authenticate'
      post 'leetcode/sync_profile', to: 'leetcode_auth#sync_profile'
      get 'leetcode/check_username/:username', to: 'leetcode_auth#check_username_availability'
    end
  end

  # Dashboard route
  get 'dashboard', to: 'dashboard#index'
  
  # Logout route
  get 'logout', to: 'dashboard#logout'

  # Defines the root path route ("/")
  root "home#index"
end
