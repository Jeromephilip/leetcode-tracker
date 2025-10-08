Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes for LeetCode integration
  namespace :api do
    namespace :v1 do
      post "leetcode/authenticate", to: "leetcode_auth#authenticate"
      post "leetcode/sync_profile", to: "leetcode_auth#sync_profile"
      post "leetcode/sync_submissions", to: "leetcode_auth#sync_submissions"
      get "leetcode/check_username/:username", to: "leetcode_auth#check_username_availability"
      post "leetcode/refresh_session", to: "leetcode_auth#refresh_session"
      get "leetcode/session_health", to: "leetcode_auth#session_health"
      post "problems/notes", to: "problems#notes"
      post "spaced_repetition/review", to: "spaced_repetition#review"
      get "spaced_repetition/stats", to: "spaced_repetition#stats"
      post "spaced_repetition/sync", to: "spaced_repetition#sync"
    end
  end

  # Dashboard route
  get "dashboard", to: "dashboard#index"
  get "dashboard/link_account", to: "dashboard#link_account"

  # Problems routes
  get "problems", to: "problems#index"
  get "problems/:id", to: "problems#show", as: :problem

  # Logout route
  get "logout", to: "dashboard#logout"

  # Defines the root path route ("/")
  root "home#index"
end
