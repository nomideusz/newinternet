class User < ApplicationRecord
  include Avatar, Bannable, Bot, Mentionable, Role, Transferable

  # WebAuthn passkeys (replaces password authentication)
  has_many :webauthn_credentials, dependent: :destroy

  has_many :memberships, dependent: :delete_all
  has_many :rooms, through: :memberships

  has_many :reachable_messages, through: :rooms, source: :messages
  has_many :messages, dependent: :destroy, foreign_key: :creator_id

  has_many :push_subscriptions, class_name: "Push::Subscription", dependent: :delete_all

  has_many :boosts, dependent: :destroy, foreign_key: :booster_id
  has_many :searches, dependent: :delete_all

  has_many :sessions, dependent: :destroy
  has_many :bans, dependent: :destroy

  enum :status, %i[ active deactivated banned ], default: :active

  # WebAuthn replaces passwords - keeping bcrypt for legacy compatibility during migration
  has_secure_password validations: false

  # Username validation (lowercase, case-insensitive matching)
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, and underscores" },
            if: -> { username.present? }

  before_validation :normalize_username

  after_create_commit :grant_membership_to_open_rooms

  scope :ordered, -> { order("LOWER(name)") }
  scope :filtered_by, ->(query) { where("name like ?", "%#{query}%") }
  scope :by_username, ->(username) { where("LOWER(username) = ?", username&.downcase) }

  def initials
    name.scan(/\b\w/).join
  end

  def title
    [ name, bio ].compact_blank.join(" – ")
  end

  def deactivate
    transaction do
      close_remote_connections

      memberships.without_direct_rooms.delete_all
      push_subscriptions.delete_all
      searches.delete_all
      sessions.delete_all

      update! status: :deactivated, email_address: deactived_email_address
    end
  end

  def reset_remote_connections
    close_remote_connections reconnect: true
  end

  private
    def normalize_username
      self.username = username&.downcase&.strip
    end

    def grant_membership_to_open_rooms
      Membership.insert_all(Rooms::Open.pluck(:id).collect { |room_id| { room_id: room_id, user_id: id } })
    end

    def deactived_email_address
      email_address&.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
    end

    def close_remote_connections(reconnect: false)
      ActionCable.server.remote_connections.where(current_user: self).disconnect reconnect: reconnect
    end
end
