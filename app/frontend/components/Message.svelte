<script>
  import menuDotsHorizontal from "images/menu-dots-horizontal.svg";
  import linkIcon from "images/link.svg";
  import replyIcon from "images/reply.svg";
  import pencilIcon from "images/pencil.svg";
  import boostIcon from "images/boost.svg";

  let { message, showDaySeparator = false, currentUserId = null } = $props();

  const reactions = [
    { emoji: "👍", title: "Thumbs up" },
    { emoji: "❤️", title: "Heart" },
    { emoji: "😂", title: "Laughing" },
    { emoji: "😮", title: "Surprised" },
    { emoji: "😢", title: "Sad" },
    { emoji: "🎉", title: "Celebrate" },
  ];

  function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString(undefined, {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function formatTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
    });
  }

  function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  async function addReaction(emoji, detailsEl) {
    // Close the menu
    if (detailsEl) {
      detailsEl.removeAttribute("open");
    }
    try {
      await fetch(`/messages/${message.id}/boosts`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
          Accept: "application/json",
        },
        body: JSON.stringify({ boost: { content: emoji } }),
      });
    } catch (error) {
      console.error("Error adding reaction:", error);
    }
  }

  function copyLink(detailsEl) {
    if (detailsEl) {
      detailsEl.removeAttribute("open");
    }
    const url = `${window.location.origin}/rooms/${message.room_id}/@${message.id}`;
    navigator.clipboard.writeText(url).catch((err) => {
      console.error("Failed to copy link:", err);
    });
  }

  function handleReply(detailsEl) {
    if (detailsEl) {
      detailsEl.removeAttribute("open");
    }
    window.dispatchEvent(
      new CustomEvent("reply-to-message", { detail: { message } })
    );
  }

  function handleClickOutside(event, detailsEl) {
    if (detailsEl && detailsEl.hasAttribute("open")) {
      const menu = detailsEl.querySelector(".message__actions-menu");
      if (menu && !menu.contains(event.target) && !detailsEl.querySelector("summary").contains(event.target)) {
        detailsEl.removeAttribute("open");
      }
    }
  }

  let isCurrentUser = $derived(message.creator_id === currentUserId);
  let detailsRef = $state(null);
</script>

<svelte:document onclick={(e) => handleClickOutside(e, detailsRef)} />

<div
  class="message message--formatted"
  class:message--me={isCurrentUser}
  class:message--first-of-day={showDaySeparator}
  id="message_{message.id}"
>
  {#if showDaySeparator}
    <h2 class="message__day-separator">
      <time datetime={message.created_at}>
        {formatDate(message.created_at)}
      </time>
    </h2>
  {/if}

  <figure class="avatar message__avatar">
    {#if message.creator?.avatar_url}
      <img src={message.creator.avatar_url} alt={message.creator.name} />
    {:else}
      <span class="avatar__initials">{message.creator?.initials || "?"}</span>
    {/if}
  </figure>

  <div class="message__body">
    <div class="message__body-content">
      <div class="message__meta">
        <h3 class="message__heading">
          <span class="message__author" title={message.creator?.title || ""}>
            <strong>{message.creator?.name || "Unknown"}</strong>
          </span>
          <a
            href="/rooms/{message.room_id}/@{message.id}"
            class="message__permalink message__timestamp"
          >
            {formatTime(message.created_at)}
          </a>

          <div class="message__actions">
            <details class="position-relative" bind:this={detailsRef}>
              <summary class="btn message__action-btn message__options-btn">
                <img
                  src={menuDotsHorizontal}
                  width="20"
                  height="20"
                  class="colorize--black"
                  aria-hidden="true"
                  alt=""
                />
                <span class="for-screen-reader">Message options</span>
              </summary>

              <div class="message__actions-menu border shadow">
                <div class="quick-boosts">
                  {#each reactions as reaction}
                    <button
                      type="button"
                      title={reaction.title}
                      class="btn message__action-btn"
                      onclick={() => addReaction(reaction.emoji, detailsRef)}
                    >
                      <figure class="margin-none boost-character">{reaction.emoji}</figure>
                      <span class="for-screen-reader">{reaction.title}</span>
                    </button>
                  {/each}

                  <button
                    type="button"
                    class="btn message__action-btn message__boost-btn"
                    onclick={() => addReaction("👍", detailsRef)}
                  >
                    <img
                      src={boostIcon}
                      class="colorize--black"
                      width="20"
                      height="20"
                      aria-hidden="true"
                      alt=""
                    />
                    <span class="for-screen-reader">New boost</span>
                  </button>
                </div>

                <div class="flex flex-wrap border-top margin-block-start-half pad-block-start-half message__actions-grid">
                  <button
                    type="button"
                    class="btn message__action-btn center full-width"
                    onclick={() => handleReply(detailsRef)}
                    title="Reply"
                    aria-label="Reply"
                  >
                    <img
                      src={replyIcon}
                      class="colorize--black"
                      width="20"
                      height="20"
                      aria-hidden="true"
                      alt=""
                    />
                  </button>

                  <button
                    type="button"
                    class="btn message__action-btn center full-width"
                    onclick={() => copyLink(detailsRef)}
                    title="Copy link"
                    aria-label="Copy link"
                  >
                    <img
                      src={linkIcon}
                      class="colorize--black"
                      width="20"
                      height="20"
                      aria-hidden="true"
                      alt=""
                    />
                  </button>

                  {#if isCurrentUser}
                    <a
                      href="/rooms/{message.room_id}/messages/{message.id}/edit"
                      class="btn message__action-btn center full-width message__edit-btn"
                      title="Edit"
                      aria-label="Edit"
                    >
                      <img
                        src={pencilIcon}
                        class="colorize--black"
                        width="20"
                        height="20"
                        aria-hidden="true"
                        alt=""
                      />
                    </a>
                  {/if}
                </div>
              </div>
            </details>
          </div>
        </h3>
      </div>
      <div dir="auto">
        {@html message.body}
      </div>
    </div>
  </div>
</div>
