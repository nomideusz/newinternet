import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

export function subscribeToRoom(roomId, callbacks = {}) {
  return consumer.subscriptions.create(
    { channel: "RoomChannel", room_id: roomId },
    {
      received(data) {
        if (callbacks.onData) callbacks.onData(data)
      },
      ...callbacks
    }
  )
}

export function subscribeToUser(userId, callbacks = {}) {
  return consumer.subscriptions.create(
    { channel: "UserChannel", user_id: userId },
    {
      received(data) {
        if (callbacks.onData) callbacks.onData(data)
      },
      ...callbacks
    }
  )
}
