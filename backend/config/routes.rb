Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      # Health
      get "health", to: "health#index"

      # Expenses
      post "groups/:group_id/expenses", to: "expenses#create"
      get "groups/:group_id/expenses", to: "expenses#index"

      # Balances
      get "groups/:group_id/balances", to: "balances#index"
      get "groups/:group_id/balances/:member_id", to: "balances#show"

      # Settlements
      post "groups/:group_id/settlements", to: "settlements#create"
      post "groups/:group_id/settlements/:id/confirm", to: "settlements#confirm"
      post "groups/:group_id/settlements/:id/reject", to: "settlements#reject"
      post "groups/:group_id/settlements/:id/cancel", to: "settlements#cancel"
      get "groups/:group_id/settlements", to: "settlements#index"

      # Groups
      post "groups", to: "groups#create"
      get "groups", to: "groups#index"
      get "groups/:group_id", to: "groups#show"
      patch "groups/:group_id", to: "groups#update"
      post "groups/:group_id/archive", to: "groups#archive"
      get "groups/:group_id/inviteable_users", to: "groups#inviteable_users"

      # Group Invitations
      post "groups/:group_id/invitations", to: "invitations#create"
      post "groups/:group_id/invitations/:id/accept", to: "invitations#accept"
      post "groups/:group_id/invitations/:id/reject", to: "invitations#reject"
      get "groups/:group_id/invitations", to: "invitations#index"
      get "invitations", to: "invitations#user_index"
      post "groups/:group_id/invitations/:id/revoke", to: "invitations#revoke"

      # Group Memberships
      get "groups/:group_id/members", to: "memberships#index"
      post "groups/:group_id/leave", to: "memberships#leave"
      delete "groups/:group_id/members/:target_user_id", to: "memberships#remove"
      patch "groups/:group_id/members/:target_user_id/role", to: "memberships#update_role"

      # Users
      get "users/me", to: "users#profile"
      patch "users/me", to: "users#update_profile"
      post "users/me/email_change", to: "users#email_change"
      post "users/me/email_verification", to: "users#email_verification"
      post "users/me/deactivate", to: "users#deactivate"

      # User Notifications
      get "notifications", to: "notifications#index"
      patch "notifications/:id/mark_as_read", to: "notifications#mark_as_read"

      # Authentication
      post "auth/register", to: "auth#register"
      post "auth/verify_email", to: "auth#verify_email"
      post "auth/login", to: "auth#login"
    end
  end

  if Rails.env.test?
    get "authentication_test", to: "authentication_test#index"
  end

end
