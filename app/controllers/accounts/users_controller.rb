class Accounts::UsersController < ApplicationController
  before_action :ensure_can_administer, :set_user, only: %i[ update destroy ]

  def index
    users = User.active.ordered.without_bots
    
    render inertia: "Accounts/Users/Index", props: {
      users: users.map { |u| user_presenter(u) },
      account: account_presenter,
      currentUser: user_presenter(Current.user),
      canAdminister: Current.user.can_administer?,
      sidebar: sidebar_props
    }
  end

  def update
    @user.update(role_params)
    redirect_to account_users_url
  end

  def destroy
    @user.deactivate
    redirect_to account_users_url
  end

  private
    def set_user
      @user = User.active.find(params[:user_id] || params[:id])
    end

    def role_params
      { role: params.require(:user)[:role].presence_in(%w[ member administrator ]) || "member" }
    end

    def user_presenter(user)
      {
        id: user.id,
        name: user.name,
        avatar_url: user.avatar_url,
        role: user.role,
        is_bot: user.bot?
      }
    end

    def account_presenter
      {
        id: Current.account.id,
        name: Current.account.name
      }
    end

    def sidebar_props
      memberships = Current.user.memberships.includes(room: :last_message).order(created_at: :asc)
      MembershipPresenter.new(memberships, Current.user).sidebar_props.merge(
        canCreateRooms: Current.user.can_create_rooms?
      )
    end
end
