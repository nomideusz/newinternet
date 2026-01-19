class Users::ProfilesController < ApplicationController
  layout "inertia"

  before_action :set_user
  before_action :load_sidebar_data, only: :show

  def show
    memberships = Current.user.memberships.with_ordered_room

    render inertia: "Users/Profiles/Show", props: {
      page: { title: @user.name, bodyClass: "sidebar" },
      currentUser: UserPresenter.new(@user, view: :profile).as_json,
      memberships: memberships.map { |m| MembershipPresenter.new(m, view: :profile).as_json },
      transferUrl: session_transfer_url(@user.transfer_id),
      sidebar: {
        directMemberships: MembershipPresenter.collection(@direct_memberships, view: :sidebar),
        otherMemberships: MembershipPresenter.collection(@other_memberships, view: :sidebar),
        directPlaceholderUsers: UserPresenter.collection(@direct_placeholder_users, view: :minimal),
        canCreateRooms: Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?
      }
    }
  end

  def update
    @user.update user_params

    if request.headers["X-Inertia"]
      redirect_to user_profile_url
    else
      redirect_to user_profile_url, notice: update_notice
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def user_params
      params.require(:user).permit(:avatar, :bio).compact
    end

    def update_notice
      params[:user][:avatar] ? "It may take up to 30 minutes to change everywhere." : "✓"
    end

    def load_sidebar_data
      all_memberships = Current.user.memberships.visible.with_ordered_room
      @direct_memberships = all_memberships.select { |m| m.room.direct? }.sort_by { |m| m.room.updated_at }.reverse
      @other_memberships = all_memberships.without(@direct_memberships)

      exclude_user_ids = user_ids_already_in_direct_rooms.including(Current.user.id)
      @direct_placeholder_users = User.active.where.not(id: exclude_user_ids).order(:created_at).limit(20 - exclude_user_ids.count)
    end

    def user_ids_already_in_direct_rooms
      Membership.where(room_id: Current.user.rooms.directs.pluck(:id)).pluck(:user_id).uniq
    end
end
