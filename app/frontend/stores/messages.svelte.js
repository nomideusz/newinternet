import { subscribeToRoom } from "../cable/subscriptions"

export class MessagesStore {
  messages = $state([])
  subscription = null

  constructor(initialMessages = []) {
    this.messages = initialMessages
  }
  
  init(messages) {
    this.messages = [...messages]
  }

  add(message) {
    // Basic deduplication
    if (!this.messages.find(m => m.id === message.id)) {
      // Append and ensure sorted by created_at (assuming new messages are always newer)
      this.messages.push(message)
    }
  }

  remove(id) {
    this.messages = this.messages.filter(m => m.id !== id)
  }

  connect(roomId) {
    this.disconnect()
    
    this.subscription = subscribeToRoom(roomId, {
      onData: (data) => {
        if (data.type === "message.created") {
          this.add(data.message)
        } else if (data.type === "message.removed") {
          this.remove(data.id)
        }
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }
}
