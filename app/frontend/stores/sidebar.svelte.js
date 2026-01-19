import { subscribeToUser } from "../cable/subscriptions"

export class SidebarStore {
  directMemberships = $state([])
  otherMemberships = $state([])
  subscription = null
  roomReadHandler = null

  constructor(initialDirects = [], initialOthers = []) {
    this.directMemberships = initialDirects
    this.otherMemberships = initialOthers
  }
  
  init(directs, others) {
    this.directMemberships = directs
    this.otherMemberships = others
    
    // Listen for room-read events from chat
    this.roomReadHandler = (e) => this.handleRoomRead(e.detail.roomId)
    window.addEventListener('room-read', this.roomReadHandler)
    
    // Check if we're currently viewing a room and mark it as read
    const currentRoomMeta = document.querySelector('meta[name="current-room-id"]')
    if (currentRoomMeta) {
      const currentRoomId = parseInt(currentRoomMeta.content, 10)
      if (currentRoomId) {
        this.handleRoomRead(currentRoomId)
      }
    }
  }
  
  handleRoomRead(roomId) {
    // Clear unread status for the room
    let found = this.directMemberships.find(m => m.room.id === roomId || m.room_id === roomId)
    if (found) {
      found.unread = false
      this.directMemberships = [...this.directMemberships]
    }
    
    found = this.otherMemberships.find(m => m.room.id === roomId || m.room_id === roomId)
    if (found) {
      found.unread = false
      this.otherMemberships = [...this.otherMemberships]
    }
  }

  handleRoomCreated(membership) {
    if (membership.room.type === 'direct') {
      this.directMemberships = [membership, ...this.directMemberships]
    } else {
      this.otherMemberships = [membership, ...this.otherMemberships]
    }
  }

  handleRoomUpdated(roomId) {
    // Find and update the room/membership sort order or unread status
    // For now, simple re-sort if we had full data, but we only get IDs here usually.
    // In a real app we'd fetch the updated membership or receive it in payload.
    // For MVP, we might move the item to top.
    
    let found = this.directMemberships.find(m => m.room.id === roomId)
    if (found) {
       found.unread = true 
       // Move to top
       this.directMemberships = [found, ...this.directMemberships.filter(m => m !== found)]
    }
    
    found = this.otherMemberships.find(m => m.room.id === roomId)
    if (found) {
       found.unread = true
       // Move to top if you want shared rooms sorted by activity
    }
  }

  connect(userId) {
    this.disconnect()
    
    this.subscription = subscribeToUser(userId, {
      onData: (data) => {
        if (data.type === "room.created") {
          this.handleRoomCreated(data.membership)
        } else if (data.type === "room.updated") {
          this.handleRoomUpdated(data.roomId)
        }
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    if (this.roomReadHandler) {
      window.removeEventListener('room-read', this.roomReadHandler)
      this.roomReadHandler = null
    }
  }
}
