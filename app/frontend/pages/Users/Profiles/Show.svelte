<script>
  import { onMount, onDestroy, mount, unmount, untrack } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../../stores/sidebarManager.svelte.js";
  import ProfileNav from "../../../components/ProfileNav.svelte";
  import Modal from "../../../components/Modal.svelte";
  import ModalSection from "../../../components/ModalSection.svelte";
  import SettingsRow from "../../../components/SettingsRow.svelte";
  import Button from "../../../components/Button.svelte";

  import iconCamera from "images/camera.svg";
  import iconMinus from "images/minus.svg";
  import iconBio from "images/bio.svg";
  import iconPerson from "images/person.svg";
  import iconCheck from "images/check.svg";
  import iconQrCode from "images/qr-code.svg";
  import iconCopyPaste from "images/copy-paste.svg";
  import iconShare from "images/share.svg";
  import iconLaptop from "images/laptop.svg";
  import iconTransfer from "images/transfer.svg";
  import iconMobilePhone from "images/mobile-phone.svg";
  import iconMessages from "images/messages.svg";
  import iconSettings from "images/settings.svg";

  let {
    page,
    currentUser,
    memberships = [],
    transferUrl,
    sidebar = {},
  } = $props();

  // Track mounted nav instance
  let navInstance = null;

  onMount(() => {
    // Mount sidebar
    if (sidebar && Object.keys(sidebar).length > 0) {
      sidebarManager.mount({
        ...sidebar,
        currentUser,
      });
    }

    // Mount nav
    const navEl = document.getElementById("nav-content");
    if (navEl) {
      navEl.innerHTML = "";
      navInstance = mount(ProfileNav, {
        target: navEl,
        props: { currentUser },
      });
    }
  });

  onDestroy(() => {
    if (navInstance) {
      try { unmount(navInstance); } catch (e) {}
      navInstance = null;
    }
  });

  // Form state
  const initialBio = untrack(() => currentUser?.bio ?? "");
  let bio = $state(initialBio);
  let isSubmitting = $state(false);
  let avatarPreview = $state(null);

  // Modal state
  let showTransferModal = $state(false);
  let showNotificationsModal = $state(false);

  // Split memberships
  let directMemberships = $derived(memberships.filter((m) => m.room.type === "direct"));
  let sharedMemberships = $derived(memberships.filter((m) => m.room.type !== "direct"));

  function handleAvatarChange(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => { avatarPreview = e.target.result; };
    reader.readAsDataURL(file);

    const formData = new FormData();
    formData.append("user[avatar]", file);

    router.post("/profile", formData, {
      forceFormData: true,
      preserveScroll: true,
      onFinish: () => { avatarPreview = null; },
    });
  }

  function handleDeleteAvatar() {
    router.delete(`/users/${currentUser.id}/avatar`, { preserveScroll: true });
  }

  function handleBioSubmit(event) {
    event.preventDefault();
    isSubmitting = true;

    router.patch(
      "/profile",
      { user: { bio } },
      {
        preserveScroll: true,
        onFinish: () => { isSubmitting = false; },
      }
    );
  }

  function handleInvolvementChange(roomId, newInvolvement) {
    router.patch(
      `/rooms/${roomId}/involvement`,
      { involvement: newInvolvement },
      { preserveScroll: true }
    );
  }

  function copyToClipboard(text) {
    navigator.clipboard.writeText(text);
  }

  function shareUrl(url, title, text) {
    if (navigator.share) {
      navigator.share({ title, text, url });
    } else {
      copyToClipboard(url);
    }
  }

  function openQrCode(url) {
    const encodedUrl = encodeURIComponent(url);
    window.open(`/qr_code/${encodedUrl}`, "_blank", "width=400,height=400");
  }

  const involvementOptions = [
    { value: "everything", label: "Everything" },
    { value: "mentions", label: "Mentions" },
    { value: "nothing", label: "Nothing" },
  ];

  function getInvolvementLabel(value) {
    return involvementOptions.find(o => o.value === value)?.label || value;
  }
</script>

<svelte:head>
  <title>{currentUser?.name} - Profile</title>
</svelte:head>

<div class="settings-page">
  <div class="settings-container">
    <!-- Header with avatar -->
    <header class="settings-header">
      <div class="avatar-section">
        <label class="avatar-upload">
          <img
            src={avatarPreview || currentUser?.avatar_url}
            alt={currentUser?.name}
            class="avatar-image"
          />
          <input
            type="file"
            accept="image/*"
            onchange={handleAvatarChange}
            class="sr-only"
          />
          <span class="avatar-upload-overlay">
            <img src={iconCamera} alt="" width="20" height="20" />
          </span>
        </label>
        
        {#if currentUser?.has_avatar}
          <button
            type="button"
            class="avatar-delete-btn"
            onclick={handleDeleteAvatar}
            title="Remove avatar"
          >
            <img src={iconMinus} alt="" width="16" height="16" />
          </button>
        {/if}
      </div>
      
      <div class="user-info">
        <h1 class="user-name">{currentUser?.name}</h1>
        <span class="user-handle">@{currentUser?.username}</span>
      </div>
    </header>

    <!-- Bio section -->
    <form onsubmit={handleBioSubmit} class="bio-section">
      <label class="bio-label">
        <span class="bio-label-text">Bio</span>
        <textarea
          bind:value={bio}
          class="bio-input"
          placeholder="A few words about yourself…"
          maxlength="200"
          rows="3"
        ></textarea>
      </label>
      
      {#if bio !== initialBio}
        <div class="bio-actions">
          <Button variant="primary" type="submit" loading={isSubmitting}>
            Save changes
          </Button>
        </div>
      {/if}
    </form>

    <!-- Settings sections -->
    <div class="settings-sections">
      {#if memberships.length > 0}
        <ModalSection title="Notifications" description="Manage notifications for each room" border={false} padding={false}>
          <SettingsRow
            label="Room notifications"
            description="{memberships.length} rooms"
            icon={iconMessages}
            onclick={() => showNotificationsModal = true}
          />
        </ModalSection>
      {/if}

      {#if transferUrl}
        <ModalSection title="Account" border={false} padding={false}>
          <SettingsRow
            label="Login on another device"
            description="Transfer your session to another browser or device"
            icon={iconTransfer}
            onclick={() => showTransferModal = true}
          />
        </ModalSection>
      {/if}
    </div>
  </div>
</div>

<!-- Transfer Session Modal -->
<Modal
  bind:open={showTransferModal}
  title="Login on another device"
  subtitle="Use this link to sign in automatically on another browser or device"
  size="small"
>
  <div class="transfer-content">
    <div class="transfer-icons">
      <img src={iconLaptop} alt="" width="32" height="32" class="colorize--black" />
      <img src={iconTransfer} alt="" width="24" height="24" class="colorize--black" />
      <img src={iconMobilePhone} alt="" width="32" height="32" class="colorize--black" />
    </div>

    <div class="transfer-url-box">
      <input
        type="text"
        value={transferUrl}
        readonly
        class="transfer-url-input"
        onclick={(e) => e.target.select()}
      />
    </div>
    
    <div class="transfer-actions">
      <Button variant="secondary" onclick={() => openQrCode(transferUrl)} icon={iconQrCode}>
        QR Code
      </Button>
      <Button variant="secondary" onclick={() => copyToClipboard(transferUrl)} icon={iconCopyPaste}>
        Copy
      </Button>
      <Button variant="secondary" onclick={() => shareUrl(transferUrl, "Login link", "DO NOT share this link - it logs into your account")} icon={iconShare}>
        Share
      </Button>
    </div>

    <p class="transfer-warning">
      ⚠️ This link gives full access to your account. Do not share it with others.
    </p>
  </div>
</Modal>

<!-- Notifications Modal -->
<Modal
  bind:open={showNotificationsModal}
  title="Notifications"
  subtitle="Choose what notifications you receive from each room"
  size="default"
>
  <div class="notifications-list">
    {#if sharedMemberships.length > 0}
      <div class="notifications-group">
        <h4 class="notifications-group-title">Rooms</h4>
        {#each sharedMemberships as membership (membership.id)}
          <div class="notification-item">
            <span class="notification-room-name">{membership.room.display_name}</span>
            <select
              class="notification-select"
              value={membership.involvement}
              onchange={(e) => handleInvolvementChange(membership.room_id, e.target.value)}
            >
              {#each involvementOptions as opt}
                <option value={opt.value}>{opt.label}</option>
              {/each}
            </select>
          </div>
        {/each}
      </div>
    {/if}

    {#if directMemberships.length > 0}
      <div class="notifications-group">
        <h4 class="notifications-group-title">Direct Messages</h4>
        {#each directMemberships as membership (membership.id)}
          <div class="notification-item">
            <span class="notification-room-name">{membership.room.display_name}</span>
            <select
              class="notification-select"
              value={membership.involvement}
              onchange={(e) => handleInvolvementChange(membership.room_id, e.target.value)}
            >
              {#each involvementOptions as opt}
                <option value={opt.value}>{opt.label}</option>
              {/each}
            </select>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</Modal>

<style>
  .settings-page {
    display: flex;
    justify-content: center;
    padding: 2rem 1rem;
    min-height: 100%;
    background: var(--color-bg);
  }

  .settings-container {
    width: 100%;
    max-width: 32rem;
    background: var(--color-message-bg);
    border-radius: 1rem;
    padding: 1.5rem;
    box-shadow: 0 1px 3px oklch(var(--lch-always-black) / 0.1);
  }

  @media (max-width: 640px) {
    .settings-page {
      padding: 1rem 0.5rem;
    }
    .settings-container {
      padding: 1rem;
      border-radius: 0.75rem;
    }
  }

  /* Header */
  .settings-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding-bottom: 1.5rem;
    margin-bottom: 1.5rem;
    border-bottom: 1px solid var(--color-border);
  }

  .avatar-section {
    position: relative;
  }

  .avatar-upload {
    position: relative;
    display: block;
    cursor: pointer;
  }

  .avatar-image {
    width: 6rem;
    height: 6rem;
    border-radius: 50%;
    object-fit: cover;
    background: var(--color-message-bg);
  }

  .avatar-upload-overlay {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: oklch(var(--lch-always-black) / 0.5);
    border-radius: 50%;
    opacity: 0;
    transition: opacity 150ms ease;
  }

  .avatar-upload:hover .avatar-upload-overlay {
    opacity: 1;
  }

  .avatar-upload-overlay img {
    filter: invert(1);
  }

  .avatar-delete-btn {
    position: absolute;
    bottom: 0;
    right: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 1.75rem;
    height: 1.75rem;
    padding: 0;
    border: 2px solid var(--color-bg);
    border-radius: 50%;
    background: var(--color-negative);
    cursor: pointer;
    transition: transform 150ms ease;
  }

  .avatar-delete-btn:hover {
    transform: scale(1.1);
  }

  .avatar-delete-btn img {
    filter: invert(1);
  }

  .sr-only {
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

  .user-info {
    text-align: center;
  }

  .user-name {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0;
    line-height: 1.2;
  }

  .user-handle {
    font-size: 0.9375rem;
    color: var(--color-border-darker);
  }

  /* Bio section */
  .bio-section {
    margin-bottom: 2rem;
  }

  .bio-label {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .bio-label-text {
    font-size: 0.8125rem;
    font-weight: 500;
    color: var(--color-border-darker);
  }

  .bio-input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid var(--color-border);
    border-radius: 0.5rem;
    background: var(--color-bg);
    font-family: inherit;
    font-size: 0.9375rem;
    line-height: 1.5;
    resize: none;
    transition: border-color 150ms ease;
  }

  .bio-input:focus {
    outline: none;
    border-color: var(--color-selected-dark);
  }

  .bio-input::placeholder {
    color: var(--color-border-darker);
  }

  .bio-actions {
    display: flex;
    justify-content: flex-end;
    margin-top: 0.75rem;
  }

  /* Sections */
  .settings-sections {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  /* Transfer Modal */
  .transfer-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    align-items: center;
  }

  .transfer-icons {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.5rem 0;
  }

  .transfer-url-box {
    width: 100%;
    background: var(--color-message-bg);
    border-radius: 0.5rem;
    padding: 0.75rem;
  }

  .transfer-url-input {
    width: 100%;
    background: transparent;
    border: none;
    font-size: 0.8125rem;
    font-family: monospace;
    color: var(--color-text);
    text-align: center;
  }

  .transfer-url-input:focus {
    outline: none;
  }

  .transfer-actions {
    display: flex;
    gap: 0.5rem;
  }

  .transfer-warning {
    font-size: 0.75rem;
    color: var(--color-alert);
    text-align: center;
    margin: 0;
    padding: 0.5rem 0 0;
  }

  /* Notifications Modal */
  .notifications-list {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .notifications-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .notifications-group-title {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--color-border-darker);
    margin: 0 0 0.25rem;
  }

  .notification-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.625rem 0.75rem;
    background: var(--color-message-bg);
    border-radius: 0.5rem;
  }

  .notification-room-name {
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    flex: 1;
    min-width: 0;
  }

  .notification-select {
    padding: 0.375rem 0.75rem;
    border: 1px solid var(--color-border);
    border-radius: 0.375rem;
    background: var(--color-bg);
    font-size: 0.8125rem;
    cursor: pointer;
    flex-shrink: 0;
  }

  .notification-select:focus {
    outline: none;
    border-color: var(--color-selected-dark);
  }
</style>
