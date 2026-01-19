class UserPresenter < ApplicationPresenter
  def initialize(user, view: :minimal)
    @user = user
    @view = view
  end

  def as_json
    base = {
      id: @user.id,
      name: @user.name,
      avatar_url: avatar_url,
      initials: initials,
      title: @user.title
    }

    case @view
    when :full
      base.merge(full_attributes)
    when :profile
      base.merge(profile_attributes)
    when :account
      base.merge(account_attributes)
    else
      base
    end
  end

  private

  def avatar_url
    Rails.application.routes.url_helpers.fresh_user_avatar_path(@user, only_path: true)
  end

  def initials
    @user.name.split.map { |n| n[0] }.join.upcase[0, 2]
  end

  def full_attributes
    {
      email_address: @user.email_address,
      username: @user.username,
      bio: @user.bio,
      status: @user.status
    }
  end

  def profile_attributes
    {
      username: @user.username,
      bio: @user.bio,
      has_avatar: @user.avatar.attached?
    }
  end

  def account_attributes
    {
      role: @user.role,
      status: @user.status,
      is_bot: @user.bot?
    }
  end
end
