<script>
  let { membership } = $props();

  function roomPath() {
    return `/rooms/${membership.room_id}`;
  }

  function closeSidebarOnMobile() {
    // Close sidebar on screens under 100ch
    if (window.matchMedia("(max-width: 100ch)").matches) {
      const sidebar = document.getElementById("sidebar");
      if (sidebar) {
        sidebar.classList.remove("open");
      }
    }
  }
</script>

<a
  href={roomPath()}
  data-target="_top"
  id="room_{membership.room.id}_list"
  class="align-center gap room btn txt-nowrap"
  class:unread={membership.unread}
  style="--column-gap: 0.5em"
  onclick={closeSidebarOnMobile}
>
  <span class="overflow-ellipsis">{membership.room.name}</span>
</a>
