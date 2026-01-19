<script>
  import iconSearch from "images/search.svg";
  import iconMessagesOutlined from "images/messages-outlined.svg";
  import iconArrowUp from "images/arrow-up.svg";

  let { room } = $props();

  let body = $state("");
  let isSubmitting = $state(false);
  let isTyping = $state(false);
  let typingTimeout = null;

  // Reactive character counter - updates automatically when body changes
  const MAX_CHARS = 2000;
  let charCount = $derived(body.length);
  let charsRemaining = $derived(MAX_CHARS - body.length);
  let isNearLimit = $derived(charsRemaining <= 100);
  let isOverLimit = $derived(charsRemaining < 0);

  // Typing indicator - demonstrates reactive state with timers
  function handleInput() {
    isTyping = true;

    // Clear previous timeout
    if (typingTimeout) {
      clearTimeout(typingTimeout);
    }

    // Reset typing state after 1 second of no input
    typingTimeout = setTimeout(() => {
      isTyping = false;
    }, 1000);
  }

  // Get CSRF token from meta tag
  function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  async function handleSubmit(event) {
    event.preventDefault();
    event.stopPropagation();

    if (!body.trim()) return;

    isSubmitting = true;

    try {
      // Use fetch instead of Inertia router to avoid page navigation
      // Messages are broadcast via ActionCable, so we don't need the response
      const response = await fetch(`/rooms/${room.id}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
          Accept: "application/json",
        },
        body: JSON.stringify({ message: { body } }),
      });

      if (response.ok || response.status === 204 || response.status === 302) {
        // Success - message will appear via ActionCable broadcast
        body = "";
      } else {
        console.error("Failed to send message:", response.status);
      }
    } catch (error) {
      console.error("Error sending message:", error);
    } finally {
      isSubmitting = false;
    }
  }

  function handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      handleSubmit(event);
    }
  }
</script>

<div class="composer flex align-end gap position-relative">
  <a
    href="/searches"
    class="btn flex-item-no-shrink margin-block-end composer__context-btn"
  >
    <img src={iconSearch} width="20" height="20" aria-hidden="true" alt="" />
    <span class="for-screen-reader">Search</span>
  </a>

  <form onsubmit={handleSubmit} class="flex flex-item-grow">
    <fieldset class="full-width" disabled={isSubmitting} style="max-inline-size: 100%;">
      <div class="flex flex-column">
        <div
          class="flex composer__input input input--actor fill-white min-width"
          style="--input-border-radius: 1.3rem"
        >
          <div class="flex align-end gap full-width">
            <img
              src={iconMessagesOutlined}
              width="22"
              height="22"
              aria-hidden="true"
              class="composer__input-hint colorize--black"
              alt=""
            />

            <div class="flex flex-column flex-item-grow min-width gap full-width">
              <textarea
                bind:value={body}
                onkeydown={handleKeydown}
                oninput={handleInput}
                rows="1"
                class="input full-width"
                style="width: 100%; resize: none;"
                aria-label="Write a message"
                placeholder="Write a message..."
              ></textarea>

              {#if isTyping}
                <span
                  class="composer__typing-indicator txt-small"
                  style="position: absolute; left: 3rem; bottom: 0.5rem; opacity: 0.6; color: var(--color-selected-dark);"
                >
                  ✍️ typing...
                </span>
              {/if}

              {#if charCount > 0}
                <span
                  class="composer__char-count txt-small"
                  class:composer__char-count--warning={isNearLimit}
                  class:composer__char-count--error={isOverLimit}
                  style="position: absolute; right: 4rem; bottom: 0.5rem; opacity: 0.6;"
                >
                  {charsRemaining}
                </span>
              {/if}
            </div>

            <button
              type="submit"
              class="btn btn--reversed flex-item-no-shrink txt-small"
              disabled={isSubmitting || !body.trim() || isOverLimit}
            >
              <img
                src={iconArrowUp}
                width="20"
                height="20"
                aria-hidden="true"
                alt=""
              />
              <span class="for-screen-reader">Send Message</span>
            </button>
          </div>
        </div>
      </div>
    </fieldset>
  </form>
</div>
