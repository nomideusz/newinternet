<script>
  import { router } from "@inertiajs/svelte"

  let { membership } = $props()

  function roomPath() {
    return `/rooms/${membership.room_id}`
  }

  function handleClick(e) {
    e.preventDefault()
    e.stopPropagation()
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
