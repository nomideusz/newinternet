# First-run setup - creates account and first admin with WebAuthn
class FirstRunsController < ApplicationController
  allow_unauthenticated_access

  before_action :prevent_repeats

  # GET /first_run - Show first-run setup form
  def show
    @user = User.new
  end

  # POST /first_run/options - Generate WebAuthn creation options for admin
  def options
    username = params[:username]&.downcase&.strip
    name = params[:name]&.strip.presence || username

    if username.blank?
      render json: { error: "Username is required" }, status: :unprocessable_entity
      return
    end

    user_id = WebAuthn.generate_user_id
    webauthn_options = WebAuthn::Credential.options_for_create(
      user: { id: user_id, name: username, display_name: name.presence || username },
      exclude: []
    )

    session[:webauthn_first_run] = {
      challenge: webauthn_options.challenge,
      user_id: user_id,
      username: username,
      name: name.presence || username
    }

    render json: webauthn_options
  end

  # POST /first_run - Complete first-run setup with credential
  def create
    registration = session[:webauthn_first_run]

    unless registration
      render json: { error: "Setup session expired" }, status: :unprocessable_entity
      return
    end

    webauthn_credential = WebAuthn::Credential.from_create(params[:credential])
    webauthn_credential.verify(registration["challenge"])

    # Create account and first room (atomic transaction)
    ActiveRecord::Base.transaction do
      account = Account.create!(name: "New Internet")
      room = Rooms::Open.new(name: "General")

      administrator = room.creator = User.new(
        username: registration["username"],
        name: registration["name"],
        role: :administrator
      )
      room.save!

      administrator.webauthn_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count,
        nickname: "Admin passkey"
      )

      room.memberships.grant_to administrator
      session.delete(:webauthn_first_run)

      start_new_session_for administrator
    end

    render json: { redirect_url: root_path }
  rescue WebAuthn::Error => e
    Rails.logger.warn "First run WebAuthn failed: #{e.message}"
    render json: { error: "Setup failed: #{e.message}" }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    # Race condition - another process created the account
    render json: { redirect_url: root_path }
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "First run failed: #{e.message}"
    render json: { error: "Setup failed: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def prevent_repeats
    if Account.any?
      respond_to do |format|
        format.html { redirect_to root_url }
        format.json { render json: { error: "Setup already completed" }, status: :forbidden }
      end
    end
  end
end
