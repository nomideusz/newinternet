<script>
  import { onMount, tick } from "svelte";
  import Message from "./Message.svelte";

  let {
    messages = [],
    anchorMessageId = null,
    currentUserId = null,
    onscroll = undefined,
    scrollRef = $bindable(),
  } = $props();

  // Use regular variables for tracking
  let previousMessageCount = 0;
  let isNearBottom = true;
  let initialScrollDone = false;

  function isSameDay(date1, date2) {
    const d1 = new Date(date1);
    const d2 = new Date(date2);
    return d1.toDateString() === d2.toDateString();
  }

  function shouldShowDaySeparator(message, index) {
    if (index === 0) return true;
    const prevMessage = messages[index - 1];
    return !isSameDay(message.created_at, prevMessage.created_at);
  }

  function scrollToBottom(behavior = "instant") {
    if (scrollRef) {
      scrollRef.scrollTo({
        top: scrollRef.scrollHeight,
        behavior: behavior
      });
    }
  }

  function checkIfNearBottom() {
    if (scrollRef) {
      const threshold = 150; // pixels from bottom
      isNearBottom = scrollRef.scrollHeight - scrollRef.scrollTop - scrollRef.clientHeight < threshold;
    }
  }

  function handleScrollInternal(event) {
    checkIfNearBottom();
    if (onscroll) onscroll(event);
  }

  // Check for new messages and auto-scroll - called manually, not in an effect
  function checkForNewMessages() {
    const currentCount = messages.length;
    if (initialScrollDone && currentCount > previousMessageCount) {
      const wasNearBottom = isNearBottom;
      tick().then(() => {
        if (wasNearBottom) {
          scrollToBottom("smooth");
        }
        checkIfNearBottom();
      });
    }
    previousMessageCount = currentCount;
  }

  // Scroll to anchor message if specified, otherwise scroll to bottom on mount
  onMount(async () => {
    await tick();

    if (anchorMessageId) {
      const element = document.getElementById(`message_${anchorMessageId}`);
      if (element) {
        element.scrollIntoView({ behavior: "instant", block: "center" });
        element.classList.add("search-highlight");
      }
    } else {
      scrollToBottom("instant");
    }

    previousMessageCount = messages.length;
    initialScrollDone = true;
    checkIfNearBottom();
  });
  
  // Use $derived to track message count changes without causing effect loops
  // This creates a reactive binding that we can use to trigger side effects
  let messageCount = $derived(messages.length);
  
  // Use $effect.pre to react to message count changes before render
  $effect.pre(() => {
    // Access messageCount to create the dependency
    const count = messageCount;
    // Schedule the scroll check after the current batch
    if (initialScrollDone && count > previousMessageCount) {
      const wasNearBottom = isNearBottom;
      // Use queueMicrotask to run after the effect but before paint
      queueMicrotask(() => {
        tick().then(() => {
          if (wasNearBottom) {
            scrollToBottom("smooth");
          }
          checkIfNearBottom();
        });
      });
    }
    previousMessageCount = count;
  });
</script>

<div
  class="messages"
  role="log"
  aria-live="polite"
  bind:this={scrollRef}
  onscroll={handleScrollInternal}
>
  {#each messages as message, index (message.client_message_id || message.id)}
    <Message
      {message}
      showDaySeparator={shouldShowDaySeparator(message, index)}
      {currentUserId}
    />
  {/each}
</div>
