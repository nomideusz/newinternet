<script>
  import { onMount, onDestroy, tick } from "svelte";
  import iconSearch from "images/search.svg";
  import iconMessagesOutlined from "images/messages-outlined.svg";
  import iconArrowUp from "images/arrow-up.svg";

  // Props - currentUser is passed from parent component
  let { room, store = null, currentUser = null } = $props();

  let body = $state("");
  let isSubmitting = $state(false);
  let textareaRef = $state(null);
  let typingTimeout = null;
  let isCurrentlyTyping = $state(false);

  // Reactive character counter
  const MAX_CHARS = 2000;
  let charCount = $derived(body.length);
  let charsRemaining = $derived(MAX_CHARS - body.length);
  let isNearLimit = $derived(charsRemaining <= 100);
  let isOverLimit = $derived(charsRemaining < 0);

  // Generate unique client message ID
  function generateClientId() {
    return Math.random().toString(36).slice(2) + Date.now().toString(36);
  }

  // Typing indicators via store
  function handleInput() {
    autoResize();

    if (store && !isCurrentlyTyping && body.trim()) {
      isCurrentlyTyping = true;
      store.startTyping();
    }

    // Clear previous timeout
    if (typingTimeout) {
      clearTimeout(typingTimeout);
    }

    // Stop typing indicator after 2 seconds of no input
    typingTimeout = setTimeout(() => {
      if (store && isCurrentlyTyping) {
        isCurrentlyTyping = false;
        store.stopTyping();
      }
    }, 2000);
  }

  // Auto-resize textarea to fit content
  function autoResize() {
    if (textareaRef) {
      textareaRef.style.height = "auto";
      textareaRef.style.height = Math.min(textareaRef.scrollHeight, 150) + "px";
    }
  }

  // Get CSRF token from meta tag
  function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  async function handleSubmit(event) {
    event?.preventDefault();
    event?.stopPropagation();

    const messageBody = body.trim();
    if (!messageBody || isSubmitting || isOverLimit) return;

    const clientMessageId = generateClientId();

    // Store textarea reference before any state changes
    const textarea = textareaRef;

    // Stop typing indicator
    if (store && isCurrentlyTyping) {
      isCurrentlyTyping = false;
      store.stopTyping();
    }
    if (typingTimeout) {
      clearTimeout(typingTimeout);
    }

    // Optimistic UI: add message immediately
    // Use div.trix-content to match server-rendered ActionText format
    if (store && currentUser) {
      store.addOptimistic(
        clientMessageId,
        `<div class="trix-content"><p>${escapeHtml(messageBody)}</p></div>`,
        currentUser,
      );
    }

    // Clear input immediately for instant feedback
    const previousBody = body;
    body = "";
    isSubmitting = true;

    // Reset textarea height and keep focus
    if (textarea) {
      textarea.style.height = "auto";
      // Keep focus on input to prevent keyboard from closing on mobile
      textarea.focus();
    }

    try {
      const response = await fetch(`/rooms/${room.id}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
          Accept: "application/json",
        },
        body: JSON.stringify({
          message: {
            body: messageBody,
            client_message_id: clientMessageId,
          },
        }),
      });

      if (!response.ok && response.status !== 204 && response.status !== 302) {
        // Mark as failed
        if (store) {
          store.markFailed(clientMessageId);
        }
        // Restore the message for retry
        body = previousBody;
        console.error("Failed to send message:", response.status);
      }
    } catch (error) {
      // Mark as failed
      if (store) {
        store.markFailed(clientMessageId);
      }
      // Restore the message for retry
      body = previousBody;
      console.error("Error sending message:", error);
    } finally {
      isSubmitting = false;
      // Re-focus textarea after submission completes
      // Use setTimeout to ensure DOM has updated after isSubmitting change
      setTimeout(() => {
        if (textarea) {
          textarea.focus();
        }
      }, 0);
    }
  }

  function escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  function handleKeydown(event) {
    // On mobile (touch devices), only submit with send button
    // On desktop, Enter submits, Shift+Enter creates new line
    const isTouchDevice =
      "ontouchstart" in window || navigator.maxTouchPoints > 0;

    if (event.key === "Enter") {
      if (event.shiftKey) {
        // Shift+Enter: allow new line
        return;
      }

      if (isTouchDevice) {
        // On mobile, Enter key from keyboard accessory should send
        // (enterkeyhint="send" handles this)
        event.preventDefault();
        handleSubmit(event);
      } else {
        // Desktop: Enter sends, Shift+Enter for new line
        event.preventDefault();
        handleSubmit(event);
      }
    }
  }

  // Focus input on mount (desktop only)
  onMount(() => {
    const isTouchDevice =
      "ontouchstart" in window || navigator.maxTouchPoints > 0;
    if (!isTouchDevice && textareaRef) {
      textareaRef.focus();
    }
  });

  onDestroy(() => {
    if (typingTimeout) {
      clearTimeout(typingTimeout);
    }
    if (store && isCurrentlyTyping) {
      store.stopTyping();
    }
  });
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
    <fieldset class="full-width" style="max-inline-size: 100%;">
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

            <div
              class="flex flex-column flex-item-grow min-width gap full-width"
            >
              <textarea
                bind:this={textareaRef}
                bind:value={body}
                onkeydown={handleKeydown}
                oninput={handleInput}
                rows="1"
                class="input full-width"
                style="width: 100%; resize: none; max-height: 150px; overflow-y: auto;"
                aria-label="Write a message"
                placeholder="Write a message..."
                enterkeyhint="send"
                inputmode="text"
                autocomplete="off"
                autocorrect="on"
                spellcheck="true"
              ></textarea>

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
