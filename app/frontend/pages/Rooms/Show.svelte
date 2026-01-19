<script>
  import { onMount, onDestroy, mount, unmount } from "svelte";
  import RoomNav from "../../components/RoomNav.svelte";
  import MessageList from "../../components/MessageList.svelte";
  import Composer from "../../components/Composer.svelte";
  import TypingIndicator from "../../components/TypingIndicator.svelte";
  import { MessagesStore } from "../../stores/messages.svelte.js";

  let {
    page,
    room,
    messages = [],
    currentUser,
    canAdminister = false,
    anchorMessageId = null,
    sidebar = {},
  } = $props();

  // Initialize store (currentUserId will be set in effect)
  const store = new MessagesStore();

  // Track mounted nav instance (sidebar is handled by global manager)
  let navInstance = null;

  // Connect store to room
  $effect(() => {
    store.init(messages, currentUser?.id);
    store.currentUserId = currentUser?.id;
    store.connect(room.id);
    return () => store.disconnect();
  });

  onMount(() => {
    // Mount nav into the #nav element
    const navEl = document.getElementById("nav");
    if (navEl) {
      navEl.innerHTML = "";
      navInstance = mount(RoomNav, {
        target: navEl,
        props: { room, canAdminister },
      });
    }
  });

  onDestroy(() => {
    // Clean up nav component
    if (navInstance) {
      try {
        unmount(navInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      navInstance = null;
    }
  });

  let showJumpToNewest = $state(false);
  let messageAreaRef = $state(null);

  function handleScroll(event) {
    const el = event.target;
    const isNearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 100;
    showJumpToNewest = !isNearBottom;
  }

  function jumpToNewest() {
    if (messageAreaRef) {
      messageAreaRef.scrollTop = messageAreaRef.scrollHeight;
    }
  }
</script>

<svelte:head>
  <meta name="current-room-id" content={room.id} />
</svelte:head>

<div id="message-area" class="message-area">
  <MessageList
    messages={store.allMessages}
    {anchorMessageId}
    currentUserId={currentUser?.id}
    bind:scrollRef={messageAreaRef}
    onscroll={handleScroll}
  />

  {#if showJumpToNewest}
    <button
      type="button"
      class="btn btn--reversed message-area__return-to-latest"
      onclick={jumpToNewest}
    >
      Jump to newest
    </button>
  {/if}
</div>

<div class="composer-wrapper">
  <TypingIndicator users={store.typingUsers} />
  <Composer {room} {store} {currentUser} />
</div>
