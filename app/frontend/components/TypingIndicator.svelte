<script>
  let { users = [] } = $props();

  let typingText = $derived(
    users.length === 0 ? "" :
    users.length === 1 ? `${users[0].name} is typing...` :
    users.length === 2 ? `${users[0].name} and ${users[1].name} are typing...` :
    `${users[0].name} and ${users.length - 1} others are typing...`
  );
</script>

{#if users.length > 0}
  <div class="typing-indicator" aria-live="polite" aria-atomic="true">
    <span class="typing-indicator__dots">
      <span class="typing-indicator__dot"></span>
      <span class="typing-indicator__dot"></span>
      <span class="typing-indicator__dot"></span>
    </span>
    <span class="typing-indicator__text txt-small">{typingText}</span>
  </div>
{/if}

<style>
  .typing-indicator {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.25rem 1rem;
    color: var(--color-text-secondary, #666);
    font-size: 0.875rem;
    min-height: 1.5rem;
  }

  .typing-indicator__dots {
    display: flex;
    gap: 0.2rem;
  }

  .typing-indicator__dot {
    width: 6px;
    height: 6px;
    background: currentColor;
    border-radius: 50%;
    animation: typing-bounce 1.4s infinite ease-in-out both;
    opacity: 0.6;
  }

  .typing-indicator__dot:nth-child(1) {
    animation-delay: -0.32s;
  }

  .typing-indicator__dot:nth-child(2) {
    animation-delay: -0.16s;
  }

  .typing-indicator__dot:nth-child(3) {
    animation-delay: 0s;
  }

  @keyframes typing-bounce {
    0%, 80%, 100% {
      transform: scale(0.8);
      opacity: 0.4;
    }
    40% {
      transform: scale(1);
      opacity: 1;
    }
  }

  .typing-indicator__text {
    opacity: 0.8;
  }
</style>
