module Message::Broadcasts
  def broadcast_create
    broadcast_append_to room, :messages, target: [ room, :messages ]
    
    # Inertia/Svelte broadcast
    payload = MessagePresenter.new(self, view: :chat).as_json
    RoomChannel.broadcast_to room, type: "message.created", message: payload
    
    # Notify sidebar about unread/new message
    room.users.each do |user|
      UserChannel.broadcast_to user, type: "room.updated", roomId: room.id, timestamp: created_at
    end
  end

  def broadcast_remove
    broadcast_remove_to room, :messages
    RoomChannel.broadcast_to room, type: "message.removed", id: id
  end
end
