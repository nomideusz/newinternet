<script>
  import { router } from "@inertiajs/svelte"

  let { membership, currentUser } = $props()

  // room.members is populated by MembershipPresenter for direct rooms
  let members = $derived(() => {
    const roomMembers = membership.room.members || []
    return roomMembers.length > 0 ? roomMembers : [currentUser]
  })

  function getShortName(users) {
    if (users.length > 1) {
      return users.map(u => {
        const parts = u.name.split(' ').slice(0, 3)
        return parts.map(s => s[0]?.toUpperCase()).join('')
      }).join('+')
    }
    return users[0]?.name?.split(' ')[0] || ''
  }

  function roomPath() {
    return `/rooms/${membership.room_id}`
  }

  function closeSidebarOnMobile() {
    // Close sidebar on screens under 100ch
    if (window.matchMedia('(max-width: 100ch)').matches) {
      const sidebar = document.getElementById("sidebar")
      if (sidebar) {
        sidebar.classList.remove("open")
      }
    }
  }

  function handleClick() {
    closeSidebarOnMobile()
    router.visit(roomPath())
  }
</script>

<a
  href={roomPath()}
  class="direct"
  class:unread={membership.unread}
  id="list_room_{membership.room.id}"
  onclick={(e) => { e.preventDefault(); handleClick() }}
>
  {#if members().length > 1}
    <div class="avatar__group">
      {#each members().slice(0, 4) as member}
        <span class="avatar">
          <img src={member.avatar_url} width="20" height="20" aria-hidden="true" alt="" />
        </span>
      {/each}
    </div>
  {:else}
    <span class="avatar">
      <img src={members()[0]?.avatar_url} width="48" height="48" aria-hidden="true" alt="" />
    </span>
  {/if}

  <span class="direct__author flex align-center gap max-width min-width border-radius txt-small">
    <span class="txt-nowrap overflow-ellipsis">
      <span class="for-screen-reader">Ping with</span>
      {getShortName(members())}
    </span>
  </span>
</a>
