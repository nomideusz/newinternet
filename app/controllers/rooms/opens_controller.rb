class Rooms::OpensController < RoomsController
  layout "inertia", only: :new

  before_action :set_room, only: %i[ show edit update ]
  before_action :ensure_can_administer, only: %i[ update ]
  before_action :remember_last_room_visited, only: :show
  before_action :force_room_type, only: %i[ edit update ]
  before_action :ensure_permission_to_create_rooms, only: %i[ new create ]

  DEFAULT_ROOM_NAME = "New room"

  def show
    redirect_to room_url(@room)
  end

  def new
    load_sidebar_data
    @room = Rooms::Open.new(name: DEFAULT_ROOM_NAME)
    @users = User.active.ordered

    render inertia: "Rooms/Opens/New", props: {
      page: { title: "New Room", bodyClass: "sidebar" },
      room: { name: @room.name },
      users: UserPresenter.collection(@users, view: :minimal),
      typeChangePath: new_rooms_closed_path,
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
    room = Rooms::Open.create_for(room_params, users: Current.user)

    broadcast_create_room(room)
    redirect_to room_url(room)
  end

  def edit
    @users = User.active.ordered
  end

  def update
    @room.update! room_params

    broadcast_update_room
    redirect_to room_url(@room)
  end

  private
    # Allows us to edit a closed room and turn it into an open one on saving.
    def force_room_type
      @room = @room.becomes!(Rooms::Open)
    end

    def broadcast_create_room(room)
      broadcast_prepend_to :rooms, target: :shared_rooms, partial: "users/sidebars/rooms/shared", locals: { room: room }

      # Inertia/Svelte broadcast
      room.memberships.each do |membership|
        payload = MembershipPresenter.new(membership, view: :sidebar).as_json
        UserChannel.broadcast_to membership.user, type: "room.created", membership: payload
      end
    end

    def broadcast_update_room
      broadcast_replace_to :rooms, target: "room_#{@room.id}_list", partial: "users/sidebars/rooms/shared", locals: { room: @room }
    end
end
