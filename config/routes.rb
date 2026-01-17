Rails.application.routes.draw do
  root "welcome#show"

  # First-run setup (WebAuthn registration for first admin)
  # First-run setup (WebAuthn registration for first admin)
  resource :first_run, only: %i[ show create ]
  post "first_run/options", to: "first_runs#options", as: :first_run_options

  # Session management (WebAuthn authentication)
  resource :session, only: %i[ new destroy ] do
    post :options, on: :collection  # Generate WebAuthn assertion options
    post :create, on: :collection   # Verify assertion and create session
    scope module: "sessions" do
      resources :transfers, only: %i[ show update ]
    end
  end

  resource :account do
    scope module: "accounts" do
      resources :users

      resources :bots do
        scope module: "bots" do
          resource :key, only: :update
        end
      end

      resource :join_code, only: :create
      resource :logo, only: %i[ show destroy ]
      resource :custom_styles, only: %i[ edit update ]
    end
  end

  direct :fresh_account_logo do |options|
    route_for :account_logo, v: Current.account&.updated_at&.to_fs(:number), size: options[:size]
  end

  # Registration via join code (WebAuthn registration)
  get "join/:join_code", to: "registrations#new", as: :join
  post "join/:join_code/options", to: "registrations#options", as: :join_options
  post "join/:join_code/callback", to: "registrations#callback", as: :join_callback

  resources :qr_code, only: :show

  resources :users, only: :show do
    scope module: "users" do
      resource :avatar, only: %i[ show destroy ]
      resource :ban, only: %i[ create destroy ]

      scope defaults: { user_id: "me" } do
        resource :sidebar, only: :show
        resource :profile
        resources :push_subscriptions do
          scope module: "push_subscriptions" do
            resources :test_notifications, only: :create
          end
        end
      end
    end
  end

  namespace :autocompletable do
    resources :users, only: :index
  end

  direct :fresh_user_avatar do |user, options|
    route_for :user_avatar, user.avatar_token, v: user.updated_at.to_fs(:number)
  end

  resources :rooms do
    resources :messages

    post ":bot_key/messages", to: "messages/by_bots#create", as: :bot_messages

    scope module: "rooms" do
      resource :refresh, only: :show
      resource :settings, only: :show
      resource :involvement, only: %i[ show update ]
    end

    get "@:message_id", to: "rooms#show", as: :at_message
  end

  namespace :rooms do
    resources :opens
    resources :closeds
    resources :directs
  end

  resources :messages do
    scope module: "messages" do
      resources :boosts
    end
  end

  resources :searches, only: %i[ index create ] do
    delete :clear, on: :collection
  end

  resource :unfurl_link, only: :create

  get "webmanifest"    => "pwa#manifest"
  get "service-worker" => "pwa#service_worker"

  get "up" => "rails/health#show", as: :rails_health_check
end
