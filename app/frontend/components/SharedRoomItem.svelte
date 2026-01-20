<script>
  import { router } from "@inertiajs/svelte"

  let { membership } = $props()

  function roomPath() {
    return `/rooms/${membership.room_id}`
  }

  function closeSidebarOnMobile() {
    // Hide sidebar on mobile when entering a room
    if (window.matchMedia('(max-width: 100ch)').matches) {
      const sidebar = document.getElementById("sidebar")
      if (sidebar) {
        sidebar.classList.add("room-open")
      }
    }
  }

  function handleClick(e) {
    e.preventDefault()
    e.stopPropagation()
    closeSidebarOnMobile()
    console.log("[Inertia] Navigating to:", roomPath())
    router.visit(roomPath())
  }
</script>

<a
  href={roomPath()}
  id="room_{membership.room.id}_list"
  class="align-center gap room btn txt-nowrap"
  class:unread={membership.unread}
  style="--column-gap: 0.5em"
  onclick={handleClick}
>
  <span class="overflow-ellipsis">{membership.room.name}</span>
</a>
