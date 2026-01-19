<script>
  import { onMount, onDestroy, mount, unmount } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../stores/sidebarManager.svelte.js";

  import iconMessagesEmpty from "images/messages-empty.svg";

  let {
    currentUser,
    sidebar = {},
  } = $props();

  // Nav instance
  let navInstance = null;

  onMount(() => {
    // Update sidebar with data from props
    if (sidebar && Object.keys(sidebar).length > 0) {
      sidebarManager.updateFromProps(sidebar);
    }
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
</script>

<svelte:head>
  <title>No rooms yet</title>
</svelte:head>

<div id="message-area" class="message-area">
  <div class="message-area--empty min-width center">
    <figure class="center pad">
      <img src={iconMessagesEmpty} aria-hidden="true" alt="" class="colorize--black translucent" />
      <span class="for-screen-reader">{currentUser?.name}</span>
    </figure>
  </div>
</div>

<style>
  .message-area {
    display: flex;
    flex-direction: column;
    flex: 1;
    min-height: 0;
  }

  .message-area--empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    flex: 1;
    padding: 2rem;
  }

  .center {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .pad {
    padding: 2rem;
  }

  .translucent {
    opacity: 0.5;
  }

  .for-screen-reader {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }
</style>
