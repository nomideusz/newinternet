<script>
  import { onMount, onDestroy, mount, unmount } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../../stores/sidebarManager.svelte.js";

  import iconCheck from "images/check.svg";
  import iconEveryone from "images/everyone.svg";
  import iconTrash from "images/trash.svg";
  import iconArrowLeft from "images/arrow-left.svg";

  let {
    page,
    room,
    users = [],
    selectedUserIds: propSelectedUserIds = [],
    isOpenRoom: propIsOpenRoom = true,
    typeChangePath,
    cancelUrl,
    currentUser = null,
    sidebar = {},
    canAdminister = false,
  } = $props();

  // Extract initial values (these don't change after mount - intentionally capturing initial props)
  // svelte-ignore state_referenced_locally
  const initialRoomName = room?.name || "";
  // svelte-ignore state_referenced_locally
  const initialIsOpenRoom = propIsOpenRoom;
  // svelte-ignore state_referenced_locally
  const initialSelectedUserIds = propSelectedUserIds;

  // Nav instance
  let navInstance = null;

  // Form state
  let roomName = $state(initialRoomName);
  let isSubmitting = $state(false);
  let searchQuery = $state("");
  let showDeleteConfirm = $state(false);

  // Room type: true = open (everyone), false = closed (selected users)
  let isOpenRoom = $state(initialIsOpenRoom);

  // Selected users for closed room
  let selectedUserIds = $state(new Set(initialSelectedUserIds));

  // Derived state
  let filteredUsers = $derived(
    searchQuery
      ? users.filter((user) =>
          user.name.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : users
  );

  let selectedCount = $derived(selectedUserIds.size);

  let hasChanges = $derived(
    roomName !== room?.name ||
    isOpenRoom !== initialIsOpenRoom ||
    !setsEqual(selectedUserIds, new Set(initialSelectedUserIds))
  );

  function setsEqual(a, b) {
    if (a.size !== b.size) return false;
    for (const item of a) {
      if (!b.has(item)) return false;
    }
    return true;
  }

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

    // Focus the name input
    setTimeout(() => {
      const input = document.getElementById("room-name");
      if (input) {
        input.focus();
        input.select();
      }
    }, 100);
  });

  onDestroy(() => {
    if (navInstance) {
      try {
        unmount(navInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      navInstance = null;
    }
  });

  function handleSubmit(event) {
    event.preventDefault();

    if (!roomName.trim()) return;
    if (!canAdminister) return;

    // For closed rooms, must have at least one user selected
    if (!isOpenRoom && selectedUserIds.size === 0) {
      return;
    }

    isSubmitting = true;

    const endpoint = isOpenRoom
      ? `/rooms/opens/${room.id}`
      : `/rooms/closeds/${room.id}`;

    const data = {
      room: { name: roomName.trim() },
    };

    if (!isOpenRoom) {
      data.user_ids = Array.from(selectedUserIds);
    }

    router.patch(endpoint, data, {
      onFinish: () => {
        isSubmitting = false;
      },
    });
  }

  function handleCancel() {
    if (cancelUrl) {
      router.visit(cancelUrl);
    } else if (window.history.length > 1) {
      window.history.back();
    } else {
      router.visit(`/rooms/${room.id}`);
    }
  }

  function toggleRoomType() {
    isOpenRoom = !isOpenRoom;
    // Clear selection when switching to open
    if (isOpenRoom) {
      selectedUserIds = new Set();
    } else {
      // When switching to closed, select current members
      selectedUserIds = new Set(initialSelectedUserIds);
    }
  }

  function toggleUserSelection(userId) {
    const newSet = new Set(selectedUserIds);
    if (newSet.has(userId)) {
      newSet.delete(userId);
    } else {
      newSet.add(userId);
    }
    selectedUserIds = newSet;
  }

  function selectAllUsers() {
    selectedUserIds = new Set(users.map((u) => u.id));
  }

  function deselectAllUsers() {
    selectedUserIds = new Set();
  }

  function isUserSelected(userId) {
    return selectedUserIds.has(userId);
  }

  function handleDeleteRoom() {
    showDeleteConfirm = true;
  }

  function confirmDelete() {
    isSubmitting = true;
    router.delete(`/rooms/${room.id}`, {
      onFinish: () => {
        isSubmitting = false;
        showDeleteConfirm = false;
      },
    });
  }

  function cancelDelete() {
    showDeleteConfirm = false;
  }

  function handleKeydown(event) {
    if (event.key === "Escape") {
      if (showDeleteConfirm) {
        cancelDelete();
      } else {
        handleCancel();
      }
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
  <title>Edit {room?.name || "Room"}</title>
</svelte:head>

<section class="panel txt-align-center" style="view-transition-name: edit-room-{room?.id}">
  <form onsubmit={handleSubmit}>
    <div class="flex align-center gap">
      {#if canAdminister}
        <label class="flex-item-grow txt-large">
          <input
            type="text"
            id="room-name"
            bind:value={roomName}
            class="input full-width txt-large"
            required
            placeholder="Name the room"
          />
          <span class="for-screen-reader">Name this room</span>
        </label>
      {:else}
        <h1 class="flex-item-grow txt-x-large">{room?.name}</h1>
      {/if}
    </div>

    <hr class="margin-block borderless" />

    <section class="room-access margin-block pad-inline fill-shade border-radius">
      <ul class="user-filter-menu list-none margin-none padding-none">
        <!-- Everyone toggle -->
        <li class="flex align-center gap margin-none pad-block">
          <figure
            class="avatar flex-item-no-shrink"
            style="--avatar-border-radius: 0; --avatar-size: 4ch;"
          >
            <img
              src={iconEveryone}
              aria-hidden="true"
              alt=""
              class="colorize--black"
              style="background-color: transparent"
            />
            <span class="for-screen-reader">Everyone</span>
          </figure>

          <div class="min-width flex-item-grow">
            <div class="overflow-ellipsis fill-shade">
              <strong>Everyone</strong>
            </div>
            <span class="txt-small translucent">
              {#if isOpenRoom}
                All {users.length} members can access
              {:else}
                {selectedCount} of {users.length} members selected
              {/if}
            </span>
          </div>

          <hr class="separator" aria-hidden="true" />

          {#if canAdminister}
            <button
              type="button"
              onclick={toggleRoomType}
              class="btn--faux flex-inline"
            >
              <span class="switch">
                <input
                  type="checkbox"
                  class="switch__input"
                  checked={isOpenRoom}
                  readonly
                />
                <span class="switch__btn round"></span>
                <span class="for-screen-reader">
                  {isOpenRoom
                    ? "Give only some access to this room"
                    : "Give everyone access to this room"}
                </span>
              </span>
            </button>
          {/if}
        </li>

        <hr class="separator full-width" style="--border-style: solid" />

        <!-- Selection controls for closed rooms -->
        {#if !isOpenRoom && canAdminister}
          <li class="selection-controls flex align-center gap pad-block">
            <span class="txt-small translucent flex-item-grow txt-align-left">
              {selectedCount} selected
            </span>
            <button type="button" class="btn btn--small" onclick={selectAllUsers}>
              All
            </button>
            <button type="button" class="btn btn--small" onclick={deselectAllUsers}>
              None
            </button>
          </li>
        {/if}

        <!-- Search box -->
        {#if users.length > 20}
          <li class="pad-block">
            <input
              type="text"
              bind:value={searchQuery}
              class="input full-width"
              placeholder="Search members..."
            />
          </li>
        {/if}

        <!-- User list -->
        <li>
          <ul class="user-list list-none margin-none padding-none">
            {#each filteredUsers as user (user.id)}
              {@const isSelected = isOpenRoom || isUserSelected(user.id)}
              <li>
                <button
                  type="button"
                  class="user-item flex align-center gap full-width"
                  class:user-item--selected={isSelected}
                  class:user-item--selectable={!isOpenRoom && canAdminister}
                  onclick={() => !isOpenRoom && canAdminister && toggleUserSelection(user.id)}
                  disabled={isOpenRoom || !canAdminister}
                >
                  <figure class="avatar">
                    {#if user.avatar_url}
                      <img src={user.avatar_url} alt={user.name} />
                    {:else}
                      <span class="avatar__initials">{user.initials || "?"}</span>
                    {/if}
                  </figure>

                  <span class="user-name flex-item-grow txt-align-left overflow-ellipsis">
                    {user.name}
                  </span>

                  {#if isSelected}
                    <img
                      src={iconCheck}
                      alt="Selected"
                      class="icon icon--small colorize--green"
                    />
                  {/if}
                </button>
              </li>
            {/each}
          </ul>
        </li>
      </ul>
    </section>

    {#if canAdminister}
      <div class="form-actions">
        <button
          type="submit"
          class="btn btn--primary"
          disabled={isSubmitting || !hasChanges}
        >
          {#if isSubmitting}
            Saving...
          {:else}
            Save Changes
          {/if}
        </button>
      </div>
    {/if}
  </form>
</section>

<!-- Delete section -->
{#if canAdminister}
  <section class="panel txt-align-center margin-block-start">
    <button
      type="button"
      class="btn btn--danger"
      onclick={handleDeleteRoom}
      disabled={isSubmitting}
    >
      <img src={iconTrash} alt="" aria-hidden="true" class="icon" />
      Delete Room
    </button>
  </section>
{/if}

<!-- Delete confirmation modal -->
{#if showDeleteConfirm}
  <!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
  <div class="modal-backdrop" onclick={cancelDelete} role="presentation">
    <!-- svelte-ignore a11y_interactive_supports_focus -->
    <div
      class="modal-content modal-content--small"
      role="dialog"
      aria-modal="true"
      aria-labelledby="delete-modal-title"
      onclick={(e) => e.stopPropagation()}
    >
      <h3 id="delete-modal-title">Delete "{room?.name}"?</h3>
      <p class="txt-small translucent">
        This will permanently delete this room and all its messages. This action
        cannot be undone.
      </p>
      <div class="modal-actions flex gap justify-center">
        <button type="button" class="btn" onclick={cancelDelete}>
          Cancel
        </button>
        <button
          type="button"
          class="btn btn--danger"
          onclick={confirmDelete}
          disabled={isSubmitting}
        >
          {isSubmitting ? "Deleting..." : "Delete Room"}
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  /* Component-specific layout styles only */
  /* Common styles are in app/frontend/styles/shared.css */
  
  .room-access {
    max-height: 60vh;
    overflow-y: auto;
  }

  .user-filter-menu {
    display: flex;
    flex-direction: column;
  }

  .selection-controls {
    padding-inline: 0.5rem;
  }

  .form-actions {
    margin-top: var(--block-space);
  }

  /* btn--danger uses existing .btn from app CSS */
  .btn--danger {
    --btn-background: var(--color-negative);
    --btn-color: white;
    --btn-border-color: var(--color-negative);
  }

  .icon--small {
    width: 1.25em;
    height: 1.25em;
  }

  /* Use app's colorize utilities when possible */
  .colorize--green {
    filter: invert(48%) sepia(79%) saturate(2476%) hue-rotate(86deg) brightness(118%) contrast(119%);
  }
</style>
