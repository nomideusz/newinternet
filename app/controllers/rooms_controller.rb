class RoomsController < ApplicationController
  layout "inertia", only: :show

  before_action :set_room, only: %i[ show destroy ]
  before_action :ensure_can_administer, only: %i[ destroy ]
  before_action :remember_last_room_visited, only: :show

  def index
    redirect_to room_url(Current.user.rooms.last)
  end

  def show
    @messages = find_messages
    load_sidebar_data
    @body_class = "sidebar"

    render inertia: "Rooms/Show", props: {
      page: { title: helpers.room_display_name(@room), bodyClass: "sidebar" },
      room: RoomPresenter.new(@room, current_user: Current.user).as_json,
      messages: MessagePresenter.collection(@messages, view: :chat),
      currentUser: UserPresenter.new(Current.user, view: :full).as_json,
      canAdminister: Current.user.can_administer?(@room),
      anchorMessageId: params[:message_id],
      sidebar: {
        directMemberships: MembershipPresenter.collection(@direct_memberships, view: :sidebar),
        otherMemberships: MembershipPresenter.collection(@other_memberships, view: :sidebar),
        directPlaceholderUsers: UserPresenter.collection(@direct_placeholder_users, view: :minimal),
        canCreateRooms: Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?
      }
    }
  end

  def destroy
    @room.destroy

    broadcast_remove_room
    redirect_to root_url
  end

  private
    def set_room
      if room = Current.user.rooms.find_by(id: params[:room_id] || params[:id])
        @room = room
      else
        redirect_to root_url, alert: "Room not found or inaccessible"
      end
    end

    def ensure_can_administer
      head :forbidden unless Current.user.can_administer?(@room)
    end

    def ensure_permission_to_create_rooms
      if Current.account.settings.restrict_room_creation_to_administrators? && !Current.user.administrator?
        head :forbidden
      end
    end

    def find_messages
      messages = @room.messages.with_creator.with_attachment_details.with_boosts

      if show_first_message = messages.find_by(id: params[:message_id])
        @messages = messages.page_around(show_first_message)
      else
        @messages = messages.last_page
      end
    end

    def room_params
      params.require(:room).permit(:name)
    end

    def broadcast_remove_room
      broadcast_remove_to :rooms, target: [ @room, :list ]
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
