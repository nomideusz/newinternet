class RoomPresenter < ApplicationPresenter
  def initialize(room, current_user: nil)
    @room = room
    @current_user = current_user
  end

  def as_json
    {
      id: @room.id,
      name: @room.name,
      display_name: room_display_name,
      type: room_type,
      created_at: @room.created_at,
      updated_at: @room.updated_at
    }
  end

  private

  def room_display_name
    if @room.direct?
      @room.users.without(@current_user).pluck(:name).to_sentence.presence || @current_user&.name
    else
      @room.name
    end
  end

  def room_type
    case @room.type
    when "Rooms::Direct" then "direct"
    when "Rooms::Open" then "open"
    when "Rooms::Closed" then "closed"
    else "unknown"
    end
  end
end
