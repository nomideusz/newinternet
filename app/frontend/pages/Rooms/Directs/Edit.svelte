<script>
  import { onMount } from "svelte";
  import { getContext } from "svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconTrash from "images/trash.svg";

  // Props passed by InertiaX Frame
  let {
    router,
    room,
    otherUsers = [],
    cancelUrl,
    closeModal = null,
  } = $props();

  // Detect if we're in modal by checking frame context
  const ctx = getContext("inertia");
  const isInModal = ctx?.frame === "modal";

  let isDeleting = $state(false);

  onMount(() => {
    // Only mount nav if not in modal
    if (!isInModal) {
      const navEl = document.getElementById("nav");
      if (navEl) {
        navEl.innerHTML = `
          <div class="flex-item-justify-start">
            <a href="${cancelUrl || "/"}" class="btn btn--plain" data-inertia="true">
              <img src="${iconArrowLeft}" alt="" aria-hidden="true" class="icon" />
              <span>Back</span>
            </a>
          </div>
        `;
      }
    }
  });

  function handleDelete() {
    if (
      !confirm(
        "Are you sure you want to delete this ping and all messages in it? This can't be undone.",
      )
    ) {
      return;
    }

    isDeleting = true;
    router.delete(`/rooms/directs/${room.id}`, {
      onFinish: () => {
        isDeleting = false;
      },
    });
  }

  function handleKeydown(event) {
    if (event.key === "Escape" && !isInModal) {
      router.visit(cancelUrl || "/");
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
  <title>Edit settings for {room.name}</title>
</svelte:head>

<div class="full-width txt-align-center">
  <section class="directs--edit margin-block-end">
    {#each otherUsers as user}
      <div class="member flex flex-column gap fill-shade pad border-radius">
        <figure
          class="avatar center"
          style="--avatar-border-radius: 10ch; --avatar-size: 10ch;"
        >
          <img src={user.avatar_url} alt={user.name} loading="lazy" />
        </figure>
        <strong>{user.name}</strong>
      </div>
    {/each}
  </section>

  <button
    type="button"
    class="btn btn--negative center margin-block-start-large"
    onclick={handleDelete}
    disabled={isDeleting}
    aria-label="Delete Ping"
  >
    <img src={iconTrash} aria-hidden="true" alt="" />
    Ping
  </button>
</div>

<style>
  .directs--edit {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    justify-content: center;
    margin-block-end: 1rem;
  }

  .member {
    min-width: 12ch;
    align-items: center;
  }

  .margin-block-start-large {
    margin-block-start: 3rem;
  }

  /* Ensure panel width constraint is removed if class remains elsewhere */
  :global(.panel) {
    width: 100%;
    max-width: 100%;
  }
</style>
