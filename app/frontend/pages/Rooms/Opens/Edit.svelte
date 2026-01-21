<script>
  import { onMount } from "svelte";
  import { getContext } from "svelte";

  import iconCheck from "images/check.svg";
  import iconEveryone from "images/everyone.svg";
  import iconTrash from "images/trash.svg";
  import iconArrowLeft from "images/arrow-left.svg";

  // Props passed by InertiaX Frame (router is passed as prop per InertiaX docs)
  let {
    router,
    room,
    users = [],
    selectedUserIds: initialSelectedUserIds = [],
    cancelUrl,
    canAdminister = false,
    closeModal = null,
    isOpenRoom: initialIsOpenRoom = true,
  } = $props();

  // Get frame name from context to detect if we're in modal
  const ctx = getContext("inertia");
  const isInModal = ctx?.frame === "modal";

  // Form state
  let isSubmitting = $state(false);
  let isOpenRoom = $state(initialIsOpenRoom);
  let selectedUserIds = $state(new Set(initialSelectedUserIds));
  let saveSuccess = $state(false);
  let searchQuery = $state("");

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
      selectedUserIds = new Set(initialSelectedUserIds);
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

    // Delay focus to let modal finish rendering
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
    if (!canAdminister || isSubmitting) return;

    const formData = new FormData(event.target);
    const roomName = formData.get("room[name]");
    if (!roomName?.trim()) return;
    if (!isOpenRoom && selectedUserIds.size === 0) return;

    isSubmitting = true;

    const endpoint = isOpenRoom
      ? `/rooms/opens/${room.id}`
      : `/rooms/closeds/${room.id}`;
    const data = { room: { name: roomName.trim() } };
    if (!isOpenRoom) {
      data.user_ids = Array.from(selectedUserIds);
    }

    router?.patch(endpoint, data, {
      preserveScroll: true,
      onSuccess: () => {
        saveSuccess = true;
        setTimeout(() => {
          saveSuccess = false;
          if (isInModal && closeModal) closeModal();
        }, 600);
      },
      onFinish: () => {
        isSubmitting = false;
      },
    });
  }

  function handleDelete() {
    if (
      !confirm(
        "Are you sure you want to delete this room and all messages in it? This can't be undone.",
      )
    )
      return;
    isSubmitting = true;
    router?.delete(`/rooms/${room.id}`, {
      onFinish: () => (isSubmitting = false),
    });
  }
</script>

<svelte:head>
  <title>Edit {room?.name || "Room"}</title>
</svelte:head>

<section style="view-transition-name: edit-room-{room?.id}">
  <form onsubmit={handleSubmit} class="full-width">
    <!-- Room Name Input -->
    <div class="flex align-center gap margin-block-end">
      {#if canAdminister}
        <label class="flex-item-grow txt-large">
          <input
            type="text"
            name="room[name]"
            id="room_name"
            value={room?.name || ""}
            class="input full-width"
            required
            placeholder="Name the room"
          />
          <span class="for-screen-reader">Name this room</span>
        </label>
      {:else}
        <h1 class="flex-item-grow txt-x-large">{room?.name}</h1>
      {/if}
    </div>

    <hr
      class="separator full-width borderless margin-block-start margin-block-end"
    />

    <section
      class="room-access pad-inline-large fill-shade border-radius margin-block-end"
    >
      <ul class="list-none margin-none padding-none">
        <!-- Everyone row -->
        <!-- Everyone row -->
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

          {#if canAdminister}
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
          {/if}
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
          <li
            class="user-row"
            class:user-row--selectable={!isOpenRoom && canAdminister}
          >
            <button
              type="button"
              class="user-row__btn"
              onclick={() =>
                !isOpenRoom && canAdminister && toggleUser(user.id)}
              disabled={isOpenRoom || !canAdminister}
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

    {#if canAdminister}
      <button
        type="submit"
        class="save-btn"
        class:save-btn--success={saveSuccess}
        disabled={isSubmitting}
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
        <span class="for-screen-reader">Save</span>
      </button>

      <div class="txt-align-center margin-block-start-large">
        <button
          type="button"
          class="btn btn--negative btn--text btn--small"
          onclick={handleDelete}
          disabled={isSubmitting}
          aria-label="Delete {room?.name}"
        >
          <img
            src={iconTrash}
            aria-hidden="true"
            alt=""
            width="16"
            height="16"
          />
          <span class="overflow-ellipsis"
            >{room?.display_name || room?.name}</span
          >
        </button>
      </div>
    {/if}
  </form>
</section>

<style>
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
    background: #ffffff;
    color: #000;
    box-shadow: 0 2px 8px oklch(0% 0 0 / 0.15);
    cursor: pointer;
    transition:
      transform 0.15s ease,
      box-shadow 0.15s ease;
  }

  :global(:root[data-theme="dark"]) .save-btn {
    background: #333333;
    color: #ffffff;
    border: 1px solid #444;
  }

  :global(:root[data-theme="dark"]) .save-btn .icon-check {
    filter: invert(1);
  }

  .save-btn:hover:not(:disabled) {
    transform: scale(1.05);
    box-shadow: 0 4px 12px oklch(0% 0 0 / 0.2);
  }

  .save-btn:disabled {
    cursor: wait;
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

  .margin-block-start-large {
    margin-block-start: 2rem;
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

  .margin-block-start-large {
    margin-block-start: 2rem;
  }

  .margin-none {
    margin: 0 !important;
  }
</style>
