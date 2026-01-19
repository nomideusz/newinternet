class WelcomeController < ApplicationController
  layout "inertia", only: :show

  def show
    if Current.user.rooms.any?
      redirect_to room_url(last_room_visited)
    else
      load_sidebar_data
      render inertia: "Welcome/Show", props: {
        currentUser: {
          id: Current.user.id,
          name: Current.user.name,
          avatar_url: fresh_user_avatar_path(Current.user)
        },
        sidebar: {
          directMemberships: MembershipPresenter.collection(@direct_memberships, view: :sidebar),
          otherMemberships: MembershipPresenter.collection(@other_memberships, view: :sidebar),
          directPlaceholderUsers: UserPresenter.collection(@direct_placeholder_users, view: :minimal),
          canCreateRooms: Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?
        }
      }
    end
  end

  private
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
