class Rooms::DirectsController < RoomsController
  layout "inertia", only: %i[new edit]

  before_action :set_room, only: %i[ edit destroy ]

  def new
    render inertia: "Rooms/Directs/New", props: {
      page: { title: "New Ping", bodyClass: "sidebar" },
      autocompleteUrl: autocompletable_users_path,
      cancelUrl: user_sidebar_path
    }
  end

  def create
    room = Rooms::Direct.find_or_create_for(selected_users)

    broadcast_create_room(room)
    redirect_to room_url(room)
  end

  def edit
    users = @room.users.many? ? @room.users.without(Current.user) : @room.users

    render inertia: "Rooms/Directs/Edit", props: {
      page: { title: "Edit settings for #{helpers.room_display_name(@room)}", bodyClass: "sidebar" },
      room: RoomPresenter.new(@room, current_user: Current.user).as_json,
      otherUsers: UserPresenter.collection(users, view: :minimal),
      cancelUrl: room_path(@room)
    }
  end

  private
    def selected_users
      User.where(id: selected_users_ids.including(Current.user.id))
    end

    def selected_users_ids
      params.fetch(:user_ids, [])
    end

    def broadcast_create_room(room)
      room.memberships.each do |membership|
        membership.broadcast_prepend_to membership.user, :rooms, target: :direct_rooms, partial: "users/sidebars/rooms/direct"

        # Inertia/Svelte broadcast
        payload = MembershipPresenter.new(membership, view: :sidebar).as_json
        UserChannel.broadcast_to membership.user, type: "room.created", membership: payload
      end
    end

    # All users in a direct room can administer it
    def ensure_can_administer
      true
    end
end
