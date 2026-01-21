<script>
  import { getRouter } from "inertiax-svelte";
  import menuDotsHorizontal from "images/menu-dots-horizontal.svg";

  // Props
  let { room, canAdminister = false } = $props();

  // Map room type to the correct edit route and component
  function getEditInfo(room) {
    const typeRoutes = {
      open: { path: "opens", component: "Rooms/Opens/Edit" },
      closed: { path: "closeds", component: "Rooms/Opens/Edit" },
      direct: { path: "directs", component: "Rooms/Directs/Edit" },
    };
    const info = typeRoutes[room.type] || typeRoutes.open;
    return {
      url: `/rooms/${info.path}/${room.id}/edit`,
      component: info.component,
    };
  }

  function openEditModal(event) {
    event.preventDefault();
    const { url } = getEditInfo(room);
    // Use getRouter to access the modal frame's router directly
    const router = getRouter("modal");
    router.visit(url, {
      preserveUrl: true,
    });
  }

  $effect(() => {
    document.title = room.name;
  });
</script>

<nav class="nav flex align-center gap">
  <span class="btn btn--reversed btn--faux room--current">
    <h1 class="room__contents txt-medium overflow-ellipsis">
      {#if room.type === "direct"}
        <span class="for-screen-reader">Ping with</span>
      {/if}
      {room.display_name}
    </h1>
  </span>

  {#if canAdminister}
    <button onclick={openEditModal} class="btn btn--borderless">
      <img
        src={menuDotsHorizontal}
        width="20"
        height="20"
        aria-hidden="true"
        alt=""
      />
      <span class="for-screen-reader"
        >Settings for this {room.type === "direct" ? "Ping" : "room"}</span
      >
    </button>
  {/if}
</nav>
