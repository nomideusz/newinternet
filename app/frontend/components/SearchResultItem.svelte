<script>
  let { message } = $props()
</script>

<div
  class="message"
  class:message--me={message.isCurrentUser}
  id="message_{message.id}"
>
  <h2 class="message__day-separator">
    <time class="message__timestamp" datetime={message.createdAt}>
      {message.formattedDate}
    </time>
  </h2>

  <figure class="avatar message__avatar">
    {#if message.creator?.avatarUrl}
      <img src={message.creator.avatarUrl} alt={message.creator.name} />
    {:else}
      <span class="avatar__initials">{message.creator?.initials || '?'}</span>
    {/if}
  </figure>

  <div class="message__body">
    <div class="message__body-content">
      <div class="message__meta">
        <h3 class="message__heading">
          <span class="message__author" title={message.creator?.title || ''}>
            <strong>{message.creator?.name || 'Unknown'}</strong>
          </span>
          <a href={message.permalinkPath} class="message__permalink message__timestamp">
            {message.formattedTime}
          </a>
          <span class="message__room">
            <a href={message.roomPath}>{message.roomName}</a>
          </span>
        </h3>
      </div>
      <div dir="auto">
        {@html message.bodyHtml || message.body}
      </div>
    </div>
  </div>
</div>
