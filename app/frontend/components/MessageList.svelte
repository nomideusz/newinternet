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

  let previousMessageCount = $state(0);

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

  function scrollToBottom() {
    if (scrollRef) {
      scrollRef.scrollTop = scrollRef.scrollHeight;
    }
  }

  // Scroll to anchor message if specified, otherwise scroll to bottom on mount
  onMount(async () => {
    await tick();

    if (anchorMessageId) {
      const element = document.getElementById(`message_${anchorMessageId}`);
      if (element) {
        element.scrollIntoView({ behavior: "instant", block: "center" });
      }
    } else {
      scrollToBottom();
    }

    previousMessageCount = messages.length;
  });

  // Scroll to bottom when new messages arrive
  $effect(() => {
    const currentCount = messages.length;

    if (currentCount > previousMessageCount && previousMessageCount > 0) {
      // New message arrived - scroll to bottom after DOM updates
      tick().then(() => {
        scrollToBottom();
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
  {onscroll}
>
  {#each messages as message, index (message.id)}
    <Message
      {message}
      showDaySeparator={shouldShowDaySeparator(message, index)}
      {currentUserId}
    />
  {/each}
</div>
