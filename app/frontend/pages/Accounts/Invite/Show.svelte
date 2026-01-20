<script>
  import { onMount } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../../stores/sidebarManager.svelte.js";
  import Button from "../../../components/Button.svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconQrCode from "images/qr-code.svg";
  import iconCopyPaste from "images/copy-paste.svg";
  import iconShare from "images/share.svg";
  import iconRefresh from "images/refresh.svg";

  let {
    page,
    joinUrl,
    account,
    currentUser,
    canAdminister = false,
    sidebar = {},
  } = $props();

  let copied = $state(false);

  onMount(() => {
    // Mount sidebar
    if (sidebar && Object.keys(sidebar).length > 0) {
      sidebarManager.mount({
        ...sidebar,
        currentUser,
      });
    }

    // Mount nav with back button
    const navEl = document.getElementById("nav-content");
    if (navEl) {
      navEl.innerHTML = `
        <div class="flex-item-justify-start">
          <a href="/account/edit" class="btn btn--plain" data-inertia="true">
            <img src="${iconArrowLeft}" alt="" aria-hidden="true" class="icon" />
            <span>Settings</span>
          </a>
        </div>
      `;
    }
  });

  function copyToClipboard(text) {
    navigator.clipboard.writeText(text);
    copied = true;
    setTimeout(() => copied = false, 2000);
  }

  function openQrCode(url) {
    const qrUrl = `/qr_code/${encodeURIComponent(url)}`;
    window.open(qrUrl, '_blank', 'width=400,height=400');
  }

  function shareUrl(url, title, text) {
    if (navigator.share) {
      navigator.share({ url, title, text });
    } else {
      copyToClipboard(url);
    }
  }

  function handleRegenerateJoinCode() {
    if (confirm("This will invalidate the current invite link. Continue?")) {
      router.post("/account/join_code", {}, {
        preserveScroll: true
      });
    }
  }
</script>

<div class="settings-page">
  <div class="settings-content">
    <header class="settings-header">
      <h1 class="settings-title">Invite people</h1>
      <p class="settings-subtitle">Share this link to invite new members to {account?.name}</p>
    </header>

    <div class="invite-content">
      <div class="url-box">
        <input
          type="text"
          value={joinUrl}
          readonly
          class="url-input"
          onclick={(e) => e.target.select()}
        />
      </div>
      
      <div class="action-buttons">
        <Button variant="secondary" onclick={() => openQrCode(joinUrl)} icon={iconQrCode}>
          QR Code
        </Button>
        <Button variant="secondary" onclick={() => copyToClipboard(joinUrl)} icon={iconCopyPaste}>
          {copied ? "Copied!" : "Copy"}
        </Button>
        <Button variant="secondary" onclick={() => shareUrl(joinUrl, "Join link", "Join me on New Internet")} icon={iconShare}>
          Share
        </Button>
      </div>

      {#if canAdminister}
        <div class="regenerate-section">
          <button type="button" class="regenerate-btn" onclick={handleRegenerateJoinCode}>
            <img src={iconRefresh} alt="" width="14" height="14" class="colorize--black" />
            Generate new link
          </button>
          <p class="regenerate-hint">This will invalidate the current link</p>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .settings-page {
    display: flex;
    flex-direction: column;
    min-height: 100%;
    padding: var(--block-space) var(--inline-space);
  }

  .settings-content {
    max-width: 30rem;
    margin: 0 auto;
    width: 100%;
  }

  .settings-header {
    text-align: center;
    margin-bottom: var(--block-space-double);
  }

  .settings-title {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0;
  }

  .settings-subtitle {
    font-size: 0.875rem;
    color: var(--color-text-secondary);
    margin: 0.25rem 0 0;
  }

  .invite-content {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .url-box {
    background-color: var(--color-bg-secondary);
    border-radius: 0.5rem;
    padding: 0.25rem;
  }

  .url-input {
    width: 100%;
    padding: 0.75rem 1rem;
    border: none;
    background: transparent;
    font-family: monospace;
    font-size: 0.875rem;
    color: var(--color-text);
    text-align: center;
  }

  .url-input:focus {
    outline: none;
  }

  .action-buttons {
    display: flex;
    gap: 0.5rem;
    justify-content: center;
    flex-wrap: wrap;
  }

  .regenerate-section {
    text-align: center;
    padding-top: 1rem;
    border-top: 1px solid var(--color-border);
  }

  .regenerate-btn {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border: none;
    background: transparent;
    color: var(--color-text-secondary);
    font-size: 0.875rem;
    cursor: pointer;
    border-radius: 0.375rem;
    transition: background-color 150ms ease;
  }

  .regenerate-btn:hover {
    background-color: var(--color-bg-secondary);
  }

  .regenerate-hint {
    font-size: 0.75rem;
    color: var(--color-text-tertiary);
    margin: 0.5rem 0 0;
  }
</style>
