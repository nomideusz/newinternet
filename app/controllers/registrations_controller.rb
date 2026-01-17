# WebAuthn registration for new users (via join code)
class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  before_action :ensure_account_exists
  before_action :validate_join_code

  # GET /join/:join_code - Show registration form
  def new
    @user = User.new
    @join_code = params[:join_code]
  end

  # POST /join/:join_code/options - Generate WebAuthn creation options
  def options
    username = params[:username]&.downcase&.strip
    name = params[:name]&.strip

    if username.blank?
      render json: { error: "Username is required" }, status: :unprocessable_entity
      return
    end

    if User.exists?(["LOWER(username) = ?", username])
      render json: { error: "Username already taken" }, status: :unprocessable_entity
      return
    end

    user_id = WebAuthn.generate_user_id
    webauthn_options = WebAuthn::Credential.options_for_create(
      user: { id: user_id, name: username, display_name: name.presence || username },
      exclude: []
    )

    session[:webauthn_registration] = {
      challenge: webauthn_options.challenge,
      user_id: user_id,
      username: username,
      name: name.presence || username
    }

    render json: webauthn_options
  end

  # POST /join/:join_code/callback - Complete registration with credential
  def callback
    registration = session[:webauthn_registration]

    unless registration
      render json: { error: "Registration session expired" }, status: :unprocessable_entity
      return
    end

    webauthn_credential = WebAuthn::Credential.from_create(params[:credential])
    webauthn_credential.verify(registration["challenge"])

    user = User.create!(
      username: registration["username"],
      name: registration["name"],
      role: :member
    )

    user.webauthn_credentials.create!(
      external_id: webauthn_credential.id,
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count,
      nickname: "Primary passkey"
    )

    session.delete(:webauthn_registration)
    start_new_session_for user

    render json: { redirect_url: root_path }
  rescue WebAuthn::Error => e
    Rails.logger.warn "WebAuthn registration failed: #{e.message}"
    render json: { error: "Registration failed: #{e.message}" }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "User creation failed: #{e.message}"
    render json: { error: "Registration failed: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def ensure_account_exists
    redirect_to first_run_url unless Account.any?
  end

  def validate_join_code
    unless params[:join_code] == Current.account&.join_code
      redirect_to root_url, alert: "Invalid join code"
    end
  end
end
