Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      get "health", to: "health#index"
      post "groups/:group_id/expenses", to: "expenses#create"
      get "groups/:group_id/expenses", to: "expenses#index"
      get "groups/:group_id/balances", to: "balances#index"
      post "groups/:group_id/settlements", to: "settlements#create"
      post "groups/:group_id/settlements/:id/confirm", to: "settlements#confirm"
      post "groups/:group_id/settlements/:id/reject", to: "settlements#reject"
      post "groups/:group_id/settlements/:id/cancel", to: "settlements#cancel"
      get "groups/:group_id/settlements", to: "settlements#index"
      post "groups", to: "groups#create"
      get "groups", to: "groups#index"
      get "groups/:group_id", to: "groups#show"
      patch "groups/:group_id", to: "groups#update"
      post "groups/:group_id/archive", to: "groups#archive"
      post "groups/:group_id/invitations", to: "invitations#create"
      post "groups/:group_id/invitations/:id/accept", to: "invitations#accept"
      post "groups/:group_id/invitations/:id/reject", to: "invitations#reject"
      get "groups/:group_id/invitations", to: "invitations#index"
      get "invitations", to: "invitations#user_index"
    end
  end

  if Rails.env.test?
    get "authentication_test", to: "authentication_test#index"
  end

end
