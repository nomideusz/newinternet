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

// PresenceChannel extends RoomChannel but also marks the room as read
// and handles connection presence tracking
export function subscribeToPresence(roomId, callbacks = {}) {
  return consumer.subscriptions.create(
    { channel: "PresenceChannel", room_id: roomId },
    {
      received(data) {
        if (callbacks.onData) callbacks.onData(data)
      },
      // Called when the subscription is ready
      connected() {
        if (callbacks.onConnected) callbacks.onConnected()
      },
      disconnected() {
        if (callbacks.onDisconnected) callbacks.onDisconnected()
      },
      ...callbacks
    }
  )
}

export function subscribeToTyping(roomId, callbacks = {}) {
  return consumer.subscriptions.create(
    { channel: "TypingNotificationsChannel", room_id: roomId },
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
