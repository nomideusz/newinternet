# WebAuthn session management (passkey login)
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new options create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: "Too many requests" }, status: :too_many_requests }

  before_action :ensure_user_exists, only: :new

  # GET /session/new - Show login form
  def new
  end

  # POST /session/options - Generate WebAuthn assertion options for login
  def options
    user = User.active.by_username(params[:username]).first

    if user&.webauthn_credentials&.any?
      webauthn_options = WebAuthn::Credential.options_for_get(
        allow: user.webauthn_credentials.pluck(:external_id)
      )
      session[:webauthn_challenge] = webauthn_options.challenge
      session[:webauthn_user_id] = user.id

      render json: webauthn_options
    else
      render json: { error: "User not found or no passkey registered" }, status: :not_found
    end
  end

  # POST /session - Verify WebAuthn assertion and create session
  def create
    user = User.active.find(session[:webauthn_user_id])

    webauthn_credential = WebAuthn::Credential.from_get(params[:credential])
    stored_credential = user.webauthn_credentials.find_by!(external_id: webauthn_credential.id)

    webauthn_credential.verify(
      session[:webauthn_challenge],
      public_key: stored_credential.public_key,
      sign_count: stored_credential.sign_count
    )

    stored_credential.update!(sign_count: webauthn_credential.sign_count)
    session.delete(:webauthn_challenge)
    session.delete(:webauthn_user_id)

    start_new_session_for user

    render json: { redirect_url: post_authenticating_url }
  rescue WebAuthn::Error, ActiveRecord::RecordNotFound => e
    Rails.logger.warn "WebAuthn login failed: #{e.message}"
    render json: { error: "Authentication failed" }, status: :unauthorized
  end

  # DELETE /session - Log out
  def destroy
    remove_push_subscription
    terminate_current_session
    redirect_to root_url
  end

  private

  def ensure_user_exists
    redirect_to first_run_url if User.none?
  end

  def remove_push_subscription
    if endpoint = params[:push_subscription_endpoint]
      Push::Subscription.destroy_by(endpoint: endpoint, user_id: Current.user.id)
    end
  end
end
