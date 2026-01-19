<script>
  import { onMount, onDestroy } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../../stores/sidebarManager.svelte.js";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconTrash from "images/trash.svg";

  let {
    page,
    room,
    otherUsers = [],
    cancelUrl,
    currentUser = null,
    sidebar = {},
  } = $props();

  let showDeleteConfirm = $state(false);
  let isDeleting = $state(false);

  onMount(() => {
    // Mount sidebar
    if (sidebar) {
      sidebarManager.mount({
        ...sidebar,
        currentUser,
      });
    }

    // Mount nav
    const navEl = document.getElementById("nav");
    if (navEl) {
      navEl.innerHTML = `
        <div class="flex-item-justify-start">
          <a href="${cancelUrl || '/'}" class="btn btn--plain" data-inertia="true">
            <img src="${iconArrowLeft}" alt="" aria-hidden="true" class="icon" />
            <span>Back</span>
          </a>
        </div>
      `;
    }
  });

  function handleDelete() {
    if (!showDeleteConfirm) {
      showDeleteConfirm = true;
      return;
    }

    isDeleting = true;
    router.delete(`/rooms/directs/${room.id}`, {
      onFinish: () => {
        isDeleting = false;
      },
    });
  }

  function handleCancelDelete() {
    showDeleteConfirm = false;
  }

  function handleKeydown(event) {
    if (event.key === "Escape") {
      if (showDeleteConfirm) {
        handleCancelDelete();
      } else {
        router.visit(cancelUrl || "/");
      }
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
  <title>Edit settings for {room.name}</title>
</svelte:head>

<div class="panel txt-align-center">
  <section class="directs--edit margin-block-end">
    {#each otherUsers as user}
      <div class="member flex flex-column gap fill-shade pad border-radius">
        <figure class="avatar center" style="--avatar-border-radius: 10ch; --avatar-size: 10ch;">
          <img 
            src={user.avatar_url} 
            alt={user.name}
            loading="lazy"
          />
        </figure>
        <strong>{user.name}</strong>
      </div>
    {/each}
  </section>

  {#if showDeleteConfirm}
    <div class="flex flex-column gap txt-align-center">
      <p class="txt-warn margin-none">
        Are you sure you want to delete this ping and all messages in it? This can't be undone.
      </p>
      <div class="flex gap center">
        <button
          type="button"
          class="btn"
          onclick={handleCancelDelete}
          disabled={isDeleting}
        >
          Cancel
        </button>
        <button
          type="button"
          class="btn btn--negative"
          onclick={handleDelete}
          disabled={isDeleting}
        >
          <img src={iconTrash} aria-hidden="true" alt="" />
          {isDeleting ? "Deleting..." : "Yes, delete"}
        </button>
      </div>
    </div>
  {:else}
    <button
      type="button"
      class="btn btn--negative center"
      onclick={handleDelete}
      aria-label="Delete Ping"
    >
      <img src={iconTrash} aria-hidden="true" alt="" />
      Ping
    </button>
  {/if}
</div>

<style>
  .directs--edit {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    justify-content: center;
  }

  .member {
    min-width: 12ch;
    align-items: center;
  }

  .txt-warn {
    color: var(--color-warn, #e53935);
  }
</style>
