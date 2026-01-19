<script>
  import { onMount } from "svelte";
  import { router } from "@inertiajs/svelte";

  import iconCheck from "images/check.svg";
  import iconEveryone from "images/everyone.svg";

  let {
    page,
    room = { name: "New room" },
    users = [],
    sidebar = {},
    currentUser = null,
    isOpenRoom: propIsOpenRoom = true,
    typeChangePath,
    cancelUrl,
  } = $props();

  // Form state - extract initial value from prop (static after mount)
  // svelte-ignore state_referenced_locally
  let roomName = $state(room?.name || "New room");
  let isSubmitting = $state(false);
  let searchQuery = $state("");
  let modalRef = $state(null);

  // Room type: true = open (everyone), false = closed (selected users)
  // svelte-ignore state_referenced_locally
  let isOpenRoom = $state(propIsOpenRoom);

  // Selected users for closed room
  let selectedUserIds = $state(new Set());

  // Derived state
  let filteredUsers = $derived(
    searchQuery
      ? users.filter((user) =>
          user.name.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : users
  );

  let selectedCount = $derived(selectedUserIds.size);

  onMount(() => {
    // Focus the name input on mount
    setTimeout(() => {
      const input = document.querySelector('.modal-content input[type="text"]');
      if (input) {
        input.focus();
        input.select();
      }
    }, 100);
  });

  function handleSubmit(event) {
    event.preventDefault();

    if (!roomName.trim()) return;

    // For closed rooms, must have at least one user selected
    if (!isOpenRoom && selectedUserIds.size === 0) {
      return;
    }

    isSubmitting = true;

    if (isOpenRoom) {
      // Create open room
      router.post(
        "/rooms/opens",
        { room: { name: roomName.trim() } },
        {
          onFinish: () => {
            isSubmitting = false;
          },
        }
      );
    } else {
      // Create closed room with selected users
      router.post(
        "/rooms/closeds",
        {
          room: { name: roomName.trim() },
          user_ids: Array.from(selectedUserIds)
        },
        {
          onFinish: () => {
            isSubmitting = false;
          },
        }
      );
    }
  }

  function handleCancel() {
    // Use history.back() to avoid full page refresh
    if (window.history.length > 1) {
      window.history.back();
    } else {
      router.visit("/");
    }
  }

  function handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      handleCancel();
    }
  }

  function toggleRoomType() {
    isOpenRoom = !isOpenRoom;
    // Clear selection when switching to open
    if (isOpenRoom) {
      selectedUserIds = new Set();
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
    selectedUserIds = new Set(users.map(u => u.id));
  }

  function deselectAllUsers() {
    selectedUserIds = new Set();
  }

  function handleKeydown(event) {
    if (event.key === "Escape") {
      handleCancel();
    }
  }

  function isUserSelected(userId) {
    return selectedUserIds.has(userId);
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
  <title>New Room</title>
</svelte:head>

<!-- svelte-ignore a11y_click_events_have_key_events a11y_no_static_element_interactions -->
<div class="modal-backdrop" onclick={handleBackdropClick} role="presentation">
  <div class="modal-content" bind:this={modalRef} role="dialog" aria-modal="true" aria-labelledby="modal-title">
    <!-- Modal header -->
    <div class="modal-header">
      <h2 id="modal-title" class="modal-title">New Room</h2>
      <button type="button" onclick={handleCancel} class="btn modal-close" aria-label="Close">
        ✕
      </button>
    </div>

    <!-- Modal body -->
    <form onsubmit={handleSubmit}>
      <div class="modal-body">
        <div class="form-group">
          <label for="room-name" class="form-label">Room name</label>
          <input
            type="text"
            id="room-name"
            bind:value={roomName}
            class="input full-width"
            required
            placeholder="Name the room"
          />
        </div>

        <fieldset class="form-group">
          <legend class="form-label">Access</legend>
          <div class="access-section">
            <div class="access-header">
              <figure class="avatar avatar--icon">
                <img
                  src={iconEveryone}
                  aria-hidden="true"
                  alt=""
                  class="colorize--black"
                />
              </figure>

              <div class="access-info">
                <strong>Everyone</strong>
                <span class="txt-small translucent">
                  {#if isOpenRoom}
                    All {users.length} members can access
                  {:else}
                    Toggle on for open access
                  {/if}
                </span>
              </div>

              <button
                type="button"
                onclick={toggleRoomType}
                class="switch-btn"
                title={isOpenRoom ? "Switch to closed room" : "Switch to open room"}
              >
                <span class="switch">
                  <span class="switch__track" class:switch__track--on={isOpenRoom}></span>
                  <span class="switch__thumb" class:switch__thumb--on={isOpenRoom}></span>
                </span>
              </button>
            </div>

            {#if !isOpenRoom}
              <div class="selection-controls">
                <span class="txt-small">{selectedCount} of {users.length} selected</span>
                <div class="selection-buttons">
                  <button type="button" class="btn btn--small" onclick={selectAllUsers}>All</button>
                  <button type="button" class="btn btn--small" onclick={deselectAllUsers}>None</button>
                </div>
              </div>
            {/if}

            {#if users.length > 10}
              <div class="search-box">
                <input
                  type="text"
                  bind:value={searchQuery}
                  class="input full-width"
                  placeholder="Search members..."
                />
              </div>
            {/if}

            <div class="user-list">
              {#each filteredUsers as user (user.id)}
                <button
                  type="button"
                  class="user-item"
                  class:user-item--selected={isOpenRoom || isUserSelected(user.id)}
                  class:user-item--selectable={!isOpenRoom}
                  onclick={() => !isOpenRoom && toggleUserSelection(user.id)}
                  disabled={isOpenRoom}
                >
                  <figure class="avatar">
                    {#if user.avatar_url}
                      <img src={user.avatar_url} alt={user.name} />
                    {:else}
                      <span class="avatar__initials">{user.initials || "?"}</span>
                    {/if}
                  </figure>

                  <div class="user-info">
                    <strong>{user.name}</strong>
                    {#if user.title}
                      <span class="txt-small translucent">{user.title}</span>
                    {/if}
                  </div>

                  {#if isOpenRoom || isUserSelected(user.id)}
                    <span class="access-badge">✓</span>
                  {:else}
                    <span class="access-badge access-badge--empty"></span>
                  {/if}
                </button>
              {/each}
            </div>
          </div>
        </fieldset>
      </div>

      <!-- Modal footer -->
      <div class="modal-footer">
        <button
          type="button"
          onclick={handleCancel}
          class="btn"
          disabled={isSubmitting}
        >
          Cancel
        </button>
        <button
          type="submit"
          class="btn btn--reversed"
          disabled={isSubmitting || !roomName.trim() || (!isOpenRoom && selectedCount === 0)}
        >
          {#if isSubmitting}
            Creating...
          {:else}
            <img src={iconCheck} width="16" height="16" aria-hidden="true" alt="" />
            Create {isOpenRoom ? "Open" : "Closed"} Room
          {/if}
        </button>
      </div>
    </form>
  </div>
</div>

<style>
  .modal-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.6);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 1rem;
  }

  .modal-content {
    background: #1a1a1a;
    border: 1px solid var(--color-border);
    border-radius: 0.75rem;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
    width: 100%;
    max-width: 480px;
    max-height: 90vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  @media (prefers-color-scheme: light) {
    .modal-content {
      background: #ffffff;
    }
  }

  .modal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem 1.25rem;
    border-bottom: 1px solid var(--color-border);
  }

  .modal-title {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .modal-close {
    --btn-padding: 0.5rem;
    font-size: 1.25rem;
    line-height: 1;
    opacity: 0.6;
    color: var(--color-text);
  }

  .modal-close:hover {
    opacity: 1;
  }

  .modal-body {
    padding: 1.25rem;
    overflow-y: auto;
    flex: 1;
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 0.75rem;
    padding: 1rem 1.25rem;
    border-top: 1px solid var(--color-border);
  }

  .form-group {
    margin-bottom: 1.25rem;
  }

  .form-group:last-child {
    margin-bottom: 0;
  }

  .form-label {
    display: block;
    font-weight: 500;
    margin-bottom: 0.5rem;
  }

  .access-section {
    background: var(--color-message-bg);
    border-radius: 0.5rem;
    overflow: hidden;
  }

  .access-header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem 1rem;
  }

  .access-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
  }

  .switch-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.25rem;
  }

  .switch {
    display: inline-flex;
    position: relative;
    width: 2.75rem;
    height: 1.5rem;
  }

  .switch__track {
    position: absolute;
    inset: 0;
    background: var(--color-border);
    border-radius: 1rem;
    transition: background 0.2s;
  }

  .switch__track--on {
    background: var(--color-selected-dark);
  }

  .switch__thumb {
    position: absolute;
    top: 0.2rem;
    left: 0.2rem;
    width: 1.1rem;
    height: 1.1rem;
    background: white;
    border-radius: 50%;
    transition: transform 0.2s;
  }

  .switch__thumb--on {
    transform: translateX(1.25rem);
  }

  .selection-controls {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.5rem 1rem;
    border-top: 1px solid var(--color-border);
    background: rgba(0, 0, 0, 0.1);
  }

  .selection-buttons {
    display: flex;
    gap: 0.5rem;
  }

  .btn--small {
    --btn-padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
  }

  .search-box {
    padding: 0.5rem 1rem;
    border-top: 1px solid var(--color-border);
  }

  .user-list {
    max-height: 200px;
    overflow-y: auto;
    border-top: 1px solid var(--color-border);
  }

  .user-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.5rem 1rem;
    width: 100%;
    background: none;
    border: none;
    text-align: left;
    color: inherit;
    font: inherit;
    cursor: default;
  }

  .user-item--selectable {
    cursor: pointer;
  }

  .user-item--selectable:hover {
    background: rgba(255, 255, 255, 0.05);
  }

  .user-item:disabled {
    opacity: 0.7;
  }

  .user-item .avatar {
    --avatar-size: 2rem;
    flex-shrink: 0;
  }

  .user-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
  }

  .user-info strong {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .access-badge {
    color: var(--color-selected-dark);
    font-size: 0.875rem;
    width: 1.25rem;
    text-align: center;
  }

  .access-badge--empty {
    opacity: 0.3;
  }

  .access-badge--empty::before {
    content: "○";
  }

  .avatar--icon {
    --avatar-size: 2.5rem;
    background: transparent;
    flex-shrink: 0;
  }

  .avatar--icon img {
    width: 1.5rem;
    height: 1.5rem;
  }
</style>
