import { subscribeToRoom, subscribeToTyping, subscribeToPresence } from "../cable/subscriptions"

export class MessagesStore {
  messages = $state([])
  pendingMessages = $state([])
  typingUsers = $state([])
  subscription = null
  typingSubscription = null
  presenceSubscription = null
  currentUserId = null

  constructor(initialMessages = [], currentUserId = null) {
    this.messages = initialMessages
    this.currentUserId = currentUserId
  }
  
  init(messages, currentUserId = null) {
    this.messages = [...messages]
    this.currentUserId = currentUserId
  }

  // Get all messages including pending ones for display
  get allMessages() {
    // Combine real messages with pending messages
    // Filter out pending messages that have been confirmed (by client_message_id)
    const confirmedClientIds = new Set(
      this.messages
        .filter(m => m.client_message_id)
        .map(m => m.client_message_id)
    )
    
    const stillPending = this.pendingMessages.filter(
      pm => !confirmedClientIds.has(pm.client_message_id)
    )
    
    return [...this.messages, ...stillPending]
  }

  // Add optimistic message before server confirms
  addOptimistic(clientMessageId, body, creator) {
    const pendingMessage = {
      id: `pending_${clientMessageId}`,
      client_message_id: clientMessageId,
      body: body,
      plain_text_body: body.replace(/<[^>]*>/g, ''),
      created_at: new Date().toISOString(),
      creator_id: creator.id,
      creator: creator,
      pending: true,
      failed: false,
    }
    
    this.pendingMessages = [...this.pendingMessages, pendingMessage]
    return pendingMessage
  }

  // Mark pending message as failed
  markFailed(clientMessageId) {
    this.pendingMessages = this.pendingMessages.map(pm => 
      pm.client_message_id === clientMessageId 
        ? { ...pm, failed: true, pending: false }
        : pm
    )
  }

  // Remove a pending message (e.g., after retry or cancel)
  removePending(clientMessageId) {
    this.pendingMessages = this.pendingMessages.filter(
      pm => pm.client_message_id !== clientMessageId
    )
  }

  add(message) {
    // Check if this confirms a pending message
    if (message.client_message_id) {
      this.pendingMessages = this.pendingMessages.filter(
        pm => pm.client_message_id !== message.client_message_id
      )
    }
    
    // Basic deduplication by ID
    if (!this.messages.find(m => m.id === message.id)) {
      this.messages = [...this.messages, message]
    }
  }

  remove(id) {
    this.messages = this.messages.filter(m => m.id !== id)
  }

  // Typing indicators
  addTypingUser(user) {
    if (user.id === this.currentUserId) return // Don't show self
    if (!this.typingUsers.find(u => u.id === user.id)) {
      this.typingUsers = [...this.typingUsers, user]
    }
  }

  removeTypingUser(userId) {
    this.typingUsers = this.typingUsers.filter(u => u.id !== userId)
  }

  connect(roomId) {
    this.disconnect()
    
    this.subscription = subscribeToRoom(roomId, {
      onData: (data) => {
        if (data.type === "message.created") {
          this.add(data.message)
          // Remove from typing when they send a message
          if (data.message.creator_id) {
            this.removeTypingUser(data.message.creator_id)
          }
        } else if (data.type === "message.removed") {
          this.remove(data.id)
        }
      }
    })

    // Subscribe to PresenceChannel to mark room as read
    // This clears the unread indicator in sidebar
    this.presenceSubscription = subscribeToPresence(roomId, {
      onConnected: () => {
        // Room is marked as read on the server when we connect
        // Update local sidebar state
        this.markRoomAsRead(roomId)
      }
    })

    this.typingSubscription = subscribeToTyping(roomId, {
      onData: (data) => {
        // Filter out our own typing notifications
        if (data.user && data.user.id === this.currentUserId) return
        
        // Ruby symbols come as strings in JSON
        const action = String(data.action)
        
        if (action === "start") {
          this.addTypingUser(data.user)
        } else if (action === "stop") {
          this.removeTypingUser(data.user.id)
        }
      }
    })
  }

  // Notify sidebar to clear unread state
  markRoomAsRead(roomId) {
    // Dispatch a custom event that sidebar can listen to
    window.dispatchEvent(new CustomEvent('room-read', { detail: { roomId } }))
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    if (this.presenceSubscription) {
      this.presenceSubscription.unsubscribe()
      this.presenceSubscription = null
    }
    if (this.typingSubscription) {
      this.typingSubscription.unsubscribe()
      this.typingSubscription = null
    }
    this.typingUsers = []
  }

  // Send typing notification
  startTyping() {
    if (this.typingSubscription) {
      this.typingSubscription.perform("start", {})
    }
  }

  stopTyping() {
    if (this.typingSubscription) {
      this.typingSubscription.perform("stop", {})
    }
  }
}
