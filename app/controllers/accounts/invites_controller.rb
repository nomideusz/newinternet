class Accounts::InvitesController < ApplicationController
  def show
    render inertia: "Accounts/Invite/Show", props: {
      joinUrl: join_url(Current.account.join_code),
      account: account_presenter,
      currentUser: user_presenter(Current.user),
      canAdminister: Current.user.can_administer?,
      sidebar: sidebar_props
    }
  end

  private
    def user_presenter(user)
      {
        id: user.id,
        name: user.name,
        avatar_url: user.avatar_url
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
