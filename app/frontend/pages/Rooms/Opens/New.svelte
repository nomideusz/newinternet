<script>
  import { onMount, getContext } from "svelte";
  import iconCheck from "images/check.svg";
  import iconEveryone from "images/everyone.svg";
  import iconArrowLeft from "images/arrow-left.svg";

  // Props passed by InertiaX Frame
  let {
    router,
    users = [],
    cancelUrl,
    canAdminister = true, // Default to true for creator
    closeModal = null,
  } = $props();

  const ctx = getContext("inertia");
  const isInModal = ctx?.frame === "modal";

  // Form state
  // Default to Open room initially
  let isOpenRoom = $state(true);
  let roomName = $state("");
  let selectedUserIds = $state(new Set());
  let isSubmitting = $state(false);
  let saveSuccess = $state(false);
  let searchQuery = $state("");

  // Initialize selectedUserIds with everyone if starting as open (though physically empty set implies none selected in UI logic if not everyone)
  // Actually, mirror Edit logic: if open, implies all.
  // But for creation, we need to decide.
  // Logic in Edit:
  // if (isOpenRoom) selectedUserIds = new Set(users.map(u => u.id));
  // Let's do that.

  $effect(() => {
    if (isOpenRoom) {
      // conceptually all, but we might just send empty list and let backend handle "open" status
      // Actually Edit.svelte logic:
      // const endpoint = isOpenRoom ? `/rooms/opens/${room.id}` : ...
      // if (!isOpenRoom) data.user_ids = ...
      // So creating an "open" room likely doesn't need user_ids.
    }
  });

  let filteredUsers = $derived(
    users.filter((u) =>
      u.name.toLowerCase().includes(searchQuery.toLowerCase()),
    ),
  );

  function toggleRoomType() {
    isOpenRoom = !isOpenRoom;
    if (isOpenRoom) {
      selectedUserIds = new Set(users.map((u) => u.id));
    } else {
      selectedUserIds = new Set();
    }
  }

  function toggleUser(userId) {
    const newSet = new Set(selectedUserIds);
    if (newSet.has(userId)) {
      newSet.delete(userId);
    } else {
      newSet.add(userId);
    }
    selectedUserIds = newSet;
  }

  onMount(() => {
    // If open room default, maybe pre-select everyone or just treat as "open" type
    // In Edit.svelte, `isOpenRoom` determines the ENDPOINT.
    // So if isOpenRoom is true, we post to /rooms/opens. If false, likely /rooms/closeds (if such route exists for create).
    // The ruby file was `new.html.erb` in `rooms/opens`.
    // It suggests this page Creates a room.

    // Let's assume we post to /rooms/opens for open rooms.
    // What if they toggle to closed?
    // Edit.svelte uses `type_change_path` in ruby.

    if (!isInModal) {
      const navEl = document.getElementById("nav");
      if (navEl) {
        navEl.innerHTML = `
          <div class="flex-item-justify-start">
            <a href="${cancelUrl || "/"}" class="btn btn--plain" data-inertia="true">
              <img src="${iconArrowLeft}" alt="" aria-hidden="true" />
              <span>Back</span>
            </a>
          </div>
        `;
      }
    }

    // Delay focus
    requestAnimationFrame(() => {
      const input = document.getElementById("room_name");
      if (input) {
        input.focus();
        input.select();
      }
    });
  });

  function handleSubmit(event) {
    event.preventDefault();
    if (isSubmitting) return;
    if (!roomName.trim()) return;

    // If closed room and no users, maybe prevent? Or allow empty.
    if (!isOpenRoom && selectedUserIds.size === 0) {
      // Warning or allow? standard seems to be allow.
    }

    isSubmitting = true;

    // Determine endpoint based on type
    const endpoint = isOpenRoom ? "/rooms/opens" : "/rooms/closeds";
    const data = { room: { name: roomName.trim() } };

    if (!isOpenRoom) {
      data.user_ids = Array.from(selectedUserIds);
    }

    router.post(endpoint, data, {
      preserveScroll: true,
      onSuccess: () => {
        saveSuccess = true;
        setTimeout(() => {
          saveSuccess = false;
          if (isInModal && closeModal) closeModal();
          // Standard redirect happens if not modal or if backend redirects
        }, 600);
      },
      onFinish: () => {
        isSubmitting = false;
      },
    });
  }
</script>

<svelte:head>
  <title>New chat room</title>
</svelte:head>

<section style="view-transition-name: new-room">
  <form onsubmit={handleSubmit} class="full-width">
    <!-- Room Name Input -->
    <div class="flex align-center gap margin-block-end">
      <label class="flex-item-grow txt-large">
        <input
          type="text"
          name="room[name]"
          id="room_name"
          bind:value={roomName}
          class="input full-width"
          required
          placeholder="Name the room"
        />
        <span class="for-screen-reader">Name this room</span>
      </label>
    </div>

    <!-- Align with Edit.svelte: Header is just inputs. -->

    <hr
      class="separator full-width borderless margin-block-start margin-block-end"
    />

    <section
      class="room-access pad-inline-large fill-shade border-radius margin-block-end"
    >
      <ul class="list-none margin-none padding-none">
        <!-- Everyone / Public Toggle -->
        <li class="flex align-center gap padding-block-small">
          <figure
            class="avatar flex-item-no-shrink"
            style="--avatar-border-radius: 0; --avatar-size: 3em;"
          >
            <img
              src={iconEveryone}
              aria-hidden="true"
              alt=""
              class="colorize--black"
              style="background-color: transparent"
            />
          </figure>

          <div class="min-width">
            <div class="overflow-ellipsis"><strong>Everyone</strong></div>
          </div>

          <hr class="separator flex-item-grow" aria-hidden="true" />

          <button
            type="button"
            class="btn--faux flex-center"
            onclick={toggleRoomType}
          >
            <span class="switch">
              <input
                type="checkbox"
                class="switch__input"
                checked={isOpenRoom}
                readonly
              />
              <span class="switch__btn round"></span>
            </span>
          </button>
        </li>

        <hr class="separator full-width" style="--border-style: solid" />

        {#if users.length > 20}
          <li class="pad-block-end">
            <label class="flex align-center gap">
              <input
                type="search"
                bind:value={searchQuery}
                placeholder="Filter…"
                class="input input--transparent full-width"
              />
            </label>
            <hr class="separator full-width" />
          </li>
        {/if}

        <!-- Users -->
        {#each filteredUsers as user (user.id)}
          {@const isSelected = isOpenRoom || selectedUserIds.has(user.id)}
          <li class="user-row" class:user-row--selectable={!isOpenRoom}>
            <button
              type="button"
              class="user-row__btn"
              onclick={() => !isOpenRoom && toggleUser(user.id)}
              disabled={isOpenRoom}
            >
              <figure
                class="avatar flex-item-no-shrink"
                style="--avatar-size: 3em;"
              >
                {#if user.avatar_url}
                  <img src={user.avatar_url} alt="" />
                {:else}
                  <span class="avatar__initials">{user.initials || "?"}</span>
                {/if}
              </figure>

              <div class="min-width txt-align-left">
                <div class="overflow-ellipsis">
                  <strong>{user.name}</strong>
                </div>
              </div>

              <hr class="separator flex-item-grow" aria-hidden="true" />

              <span
                class="user-row__check flex-item-no-shrink"
                class:user-row__check--visible={isSelected}
              >
                <img
                  src={iconCheck}
                  alt=""
                  width="20"
                  height="20"
                  class="adaptive-icon"
                />
              </span>
            </button>
          </li>
        {/each}
      </ul>
    </section>

    <!-- Save Button -->
    <button
      type="submit"
      class="save-btn"
      class:save-btn--success={saveSuccess}
      disabled={isSubmitting || !roomName}
      aria-busy={isSubmitting}
    >
      {#if isSubmitting}
        <span class="save-btn__dots">
          <span class="save-btn__dot"></span>
          <span class="save-btn__dot"></span>
          <span class="save-btn__dot"></span>
        </span>
      {:else}
        <img
          src={iconCheck}
          aria-hidden="true"
          alt=""
          width="20"
          height="20"
          class="icon-check"
        />
      {/if}
      <span class="for-screen-reader">Create Room</span>
    </button>
  </form>
</section>

<style>
  /* Copied styling from Edit.svelte for consistency */
  .room-access {
    max-height: 50vh;
    overflow-y: auto;
  }

  .room-access ul {
    padding-left: 0;
    margin: 0;
  }

  .user-row {
    list-style: none;
    padding: 0.5em 0;
    margin-left: 0;
  }

  .user-row__btn {
    display: flex;
    align-items: center;
    gap: 0.75em;
    width: 100%;
    padding: 0;
    margin: 0;
    background: none;
    border: none;
    color: inherit;
    text-align: left;
    cursor: default;
    outline: none !important;
    box-shadow: none !important;
    -webkit-appearance: none;
    appearance: none;
  }

  .user-row__btn:hover,
  .user-row__btn:focus,
  .user-row__btn:active {
    outline: none !important;
    box-shadow: none !important;
    border: none !important;
    background: none;
  }

  .user-row--selectable .user-row__btn {
    cursor: pointer;
  }

  .user-row--selectable:hover {
    opacity: 0.8;
  }

  .user-row__check {
    opacity: 0;
    transition: opacity 150ms ease;
  }

  .user-row__check--visible {
    opacity: 1;
  }

  /* Save button */
  .save-btn {
    display: grid;
    place-items: center;
    width: 3.5rem;
    height: 3.5rem;
    margin: 3rem auto 0;
    padding: 0;
    border: none;
    border-radius: 50%;
    background: #ffffff; /* Explicitly white */
    color: #000;
    box-shadow: 0 2px 8px oklch(0% 0 0 / 0.15);
    cursor: pointer;
    transition:
      transform 0.15s ease,
      box-shadow 0.15s ease;
  }

  /* Dark mode override for save button */
  :global(:root[data-theme="dark"]) .save-btn {
    background: #333333;
    color: #ffffff;
    border: 1px solid #444;
  }

  /* Ensure icon is white in dark mode within the save button */
  :global(:root[data-theme="dark"]) .save-btn .icon-check {
    filter: invert(1);
  }

  /* If we used adaptive-icon class, it might double invert if generic rule applies. 
     Safe to just manually handle .icon-check inside .save-btn for dark mode here 
     and remove specific class from HTML if needed, or rely on this specificity. */

  .save-btn:hover:not(:disabled) {
    transform: scale(1.05);
    box-shadow: 0 4px 12px oklch(0% 0 0 / 0.2);
  }

  .save-btn:disabled {
    cursor: wait;
    opacity: 0.7;
  }

  .save-btn--success {
    background: var(--color-success, #22c55e);
  }

  /* Animated dots */
  .save-btn__dots {
    display: flex;
    gap: 4px;
    align-items: center;
  }

  .save-btn__dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: currentColor;
    animation: dotPulse 1.4s ease-in-out infinite;
  }

  .save-btn__dot:nth-child(2) {
    animation-delay: 0.2s;
  }

  .save-btn__dot:nth-child(3) {
    animation-delay: 0.4s;
  }

  @keyframes dotPulse {
    0%,
    80%,
    100% {
      opacity: 0.3;
      transform: scale(0.8);
    }
    40% {
      opacity: 1;
      transform: scale(1);
    }
  }

  .padding-block-small {
    padding-top: 0.5em;
    padding-bottom: 0.5em;
  }

  .pad-inline-large {
    padding-inline: 1.5rem;
  }

  .pad-block-end {
    padding-bottom: 0.5rem;
  }

  .flex-center {
    display: flex;
    align-items: center;
  }

  /* Adaptive icon color for dark mode */
  :global(:root[data-theme="dark"]) .adaptive-icon {
    filter: invert(1) !important;
  }

  @media (prefers-color-scheme: dark) {
    .adaptive-icon {
      filter: invert(1) !important;
    }
  }

  .margin-block-end {
    margin-block-end: 1.5rem;
  }

  .margin-block-start {
    margin-block-start: 1.5rem;
  }

  /* Override panel width constraints if any */
  :global(.panel) {
    width: 100%;
    max-width: 100%;
  }

  .margin-none {
    margin: 0 !important;
  }
</style>
