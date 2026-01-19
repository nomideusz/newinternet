class Rooms::ClosedsController < RoomsController
  layout "inertia", only: %i[new edit]

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
    @room = Rooms::Closed.new(name: DEFAULT_ROOM_NAME)
    @users = User.active.ordered

    render inertia: "Rooms/Opens/New", props: {
      page: { title: "New Room", bodyClass: "sidebar" },
      room: { name: @room.name },
      users: UserPresenter.collection(@users, view: :minimal),
      isOpenRoom: false,
      typeChangePath: new_rooms_open_path,
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
    room = Rooms::Closed.create_for(room_params, users: grantees)

    broadcast_create_room(room)
    redirect_to room_url(room)
  end

  def edit
    load_sidebar_data
    @users = User.active.ordered
    selected_user_ids = @room.users.pluck(:id)

    render inertia: "Rooms/Opens/Edit", props: {
      page: { title: "Edit #{@room.name}", bodyClass: "sidebar" },
      room: RoomPresenter.new(@room, current_user: Current.user).as_json,
      users: UserPresenter.collection(@users, view: :minimal),
      selectedUserIds: selected_user_ids,
      isOpenRoom: false,
      typeChangePath: edit_rooms_open_path(@room),
      cancelUrl: room_path(@room),
      currentUser: UserPresenter.new(Current.user, view: :minimal).as_json,
      canAdminister: Current.user.can_administer?(@room),
      sidebar: {
        directMemberships: MembershipPresenter.collection(@direct_memberships, view: :sidebar),
        otherMemberships: MembershipPresenter.collection(@other_memberships, view: :sidebar),
        directPlaceholderUsers: UserPresenter.collection(@direct_placeholder_users, view: :minimal),
        canCreateRooms: Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?
      }
    }
  end

  def update
    @room.update! room_params
    @room.memberships.revise(granted: grantees, revoked: revokees)

    broadcast_update_room
    redirect_to room_url(@room)
  end

  private
    # Allows us to edit an open room and turn it into a closed one on saving.
    def force_room_type
      @room = @room.becomes!(Rooms::Closed)
    end

    def grantees
      User.where(id: grantee_ids)
    end

    def revokees
      @room.users.where.not(id: grantee_ids)
    end

    def grantee_ids
      params.fetch(:user_ids, [])
    end

    def broadcast_create_room(room)
      each_user_and_html_for(room) do |user, html|
        broadcast_prepend_to user, :rooms, target: :shared_rooms, html: html
      end
    end

    def broadcast_update_room
      each_user_and_html_for(@room) do |user, html|
        broadcast_replace_to user, :rooms, target: "room_#{@room.id}_list", html: html
      end
    end

    def each_user_and_html_for(room)
      # Optimization to avoid rendering the same partial for every user
      html = render_to_string(partial: "users/sidebars/rooms/shared", locals: { room: room })

      room.users.each { |user| yield user, html }
    end
end
