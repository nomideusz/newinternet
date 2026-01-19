class Rooms::DirectsController < RoomsController
  layout "inertia", only: :new

  before_action :set_room, only: %i[ edit destroy ]

  def new
    load_sidebar_data

    render inertia: "Rooms/Directs/New", props: {
      page: { title: "New Ping", bodyClass: "sidebar" },
      autocompleteUrl: autocompletable_users_path,
      cancelUrl: user_sidebar_path,
      currentUser: UserPresenter.new(Current.user, view: :minimal).as_json,
      sidebar: {
        directMemberships: MembershipPresenter.collection(@direct_memberships, view: :sidebar),
        otherMemberships: MembershipPresenter.collection(@other_memberships, view: :sidebar),
        directPlaceholderUsers: UserPresenter.collection(@direct_placeholder_users, view: :minimal),
        canCreateRooms: Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?
      }
    }
  end

  def create
    room = Rooms::Direct.find_or_create_for(selected_users)

    broadcast_create_room(room)
    redirect_to room_url(room)
  end

  def edit
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
