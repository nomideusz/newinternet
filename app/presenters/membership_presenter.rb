class MembershipPresenter < ApplicationPresenter
  def initialize(membership, view: :default, current_user: nil)
    @membership = membership
    @view = view
    @current_user = current_user || @membership.user
  end

  def as_json
    {
      id: @membership.id,
      room_id: @membership.room_id,
      user_id: @membership.user_id,
      unread: @membership.unread?,
      unread_at: @membership.unread_at,
      involvement: @membership.involvement,
      connected: @membership.connected,
      room: room_json
    }
  end

  private

  def room_json
    room = @membership.room
    presenter = RoomPresenter.new(room, current_user: @current_user)
    base = presenter.as_json

    if room.direct?
      members = room.users.without(@membership.user).presence || [@membership.user]
      base[:members] = members.map { |m| UserPresenter.new(m, view: :minimal).as_json }
    end

    base
  end
end
