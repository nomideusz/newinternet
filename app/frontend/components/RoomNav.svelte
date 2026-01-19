<script>
  let { room, canAdminister = false } = $props();

  import menuDotsHorizontal from "images/menu-dots-horizontal.svg";

  // Map room type to the correct edit route
  function getEditUrl(room) {
    const typeRoutes = {
      open: "opens",
      closed: "closeds",
      direct: "directs",
    };
    const routeType = typeRoutes[room.type] || "opens";
    return `/rooms/${routeType}/${room.id}/edit`;
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
    <a href={getEditUrl(room)} class="btn btn--borderless">
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
    </a>
  {/if}
</nav>
