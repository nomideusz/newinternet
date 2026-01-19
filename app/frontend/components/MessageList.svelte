<script>
  import { onMount, tick, untrack } from "svelte";
  import Message from "./Message.svelte";

  let {
    messages = [],
    anchorMessageId = null,
    currentUserId = null,
    onscroll = undefined,
    scrollRef = $bindable(),
  } = $props();

  let previousMessageCount = $state(0);
  let isNearBottom = $state(true);
  let initialScrollDone = $state(false);

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

  // Auto-scroll when new messages arrive (if user was near bottom)
  $effect(() => {
    const currentCount = messages.length;
    
    // Use untrack to read state without creating dependency
    const wasNearBottom = untrack(() => isNearBottom);
    const prevCount = untrack(() => previousMessageCount);
    const scrollDone = untrack(() => initialScrollDone);
    
    if (scrollDone && currentCount > prevCount) {
      // New message(s) arrived
      tick().then(() => {
        if (wasNearBottom) {
          // User was near bottom, auto-scroll to show new message
          scrollToBottom("smooth");
        }
        checkIfNearBottom();
      });
    }
    
    previousMessageCount = currentCount;
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
