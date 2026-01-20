<script>
  import { onMount, onDestroy, mount, unmount, untrack } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../stores/sidebarManager.svelte.js";
  import Modal from "../../components/Modal.svelte";
  import ModalSection from "../../components/ModalSection.svelte";
  import SettingsRow from "../../components/SettingsRow.svelte";
  import Toggle from "../../components/Toggle.svelte";
  import Button from "../../components/Button.svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconCamera from "images/camera.svg";
  import iconPersonAdd from "images/person-add.svg";
  import iconQrCode from "images/qr-code.svg";
  import iconCopyPaste from "images/copy-paste.svg";
  import iconShare from "images/share.svg";
  import iconPerson from "images/person.svg";
  import iconLock from "images/lock.svg";
  import iconOffice from "images/office.svg";
  import iconMessages from "images/messages.svg";
  import iconTransfer from "images/transfer.svg";
  import iconLaptop from "images/laptop.svg";
  import iconMobilePhone from "images/mobile-phone.svg";

  let {
    page,
    account,
    users = [],
    currentUser,
    canAdminister = false,
    joinUrl,
    logoUrl,
    version,
    memberships = [],
    transferUrl,
    sidebar = {},
  } = $props();

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
          <a href="/" class="btn btn--plain" data-inertia="true">
            <img src="${iconArrowLeft}" alt="" aria-hidden="true" class="icon" />
            <span>Back</span>
          </a>
        </div>
      `;
    }
  });

  // Split users into admins and members
  let administrators = $derived(users.filter((u) => u.role === "administrator"));
  let members = $derived(users.filter((u) => u.role !== "administrator"));

  // Split memberships for notifications
  let directMemberships = $derived(memberships.filter((m) => m.room?.type === "direct"));
  let sharedMemberships = $derived(memberships.filter((m) => m.room?.type !== "direct"));

  // Profile form state
  const initialBio = untrack(() => currentUser?.bio ?? "");
  let bio = $state(initialBio);
  let avatarPreview = $state(null);
  let isSubmittingBio = $state(false);

  // Account form state
  const initialAccountName = untrack(() => account?.name ?? "");
  const initialRestrictRoomCreation = untrack(
    () => account?.settings?.restrict_room_creation_to_administrators ?? false
  );
  let accountName = $state(initialAccountName);
  let isSubmittingName = $state(false);
  let logoPreview = $state(null);
  let restrictRoomCreation = $state(initialRestrictRoomCreation);

  // Modal state (only for notifications and transfer which are smaller actions)
  let showNotificationsModal = $state(false);
  let showTransferModal = $state(false);

  // === Profile handlers ===
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
    isSubmittingBio = true;

    router.patch(
      "/profile",
      { user: { bio } },
      {
        preserveScroll: true,
        onFinish: () => { isSubmittingBio = false; },
      }
    );
  }

  // === Account handlers ===
  function handleLogoChange(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => { logoPreview = e.target.result; };
    reader.readAsDataURL(file);

    const formData = new FormData();
    formData.append("account[logo]", file);

    router.patch("/account", formData, {
      forceFormData: true,
      preserveScroll: true,
      onFinish: () => { logoPreview = null; },
    });
  }

  function handleNameSubmit(event) {
    event.preventDefault();
    isSubmittingName = true;
    router.patch(
      "/account",
      { account: { name: accountName } },
      {
        preserveScroll: true,
        onFinish: () => { isSubmittingName = false; },
      }
    );
  }

  function handleRestrictRoomCreationToggle(checked) {
    restrictRoomCreation = checked;
    router.put(
      "/account",
      { account: { settings: { restrict_room_creation_to_administrators: checked } } },
      { preserveScroll: true }
    );
  }

  function handleInvolvementChange(roomId, newInvolvement) {
    router.patch(
      `/rooms/${roomId}/involvement`,
      { involvement: newInvolvement },
      { preserveScroll: true }
    );
  }

  // === Shared utilities ===
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
</script>

<svelte:head>
  <title>Settings</title>
</svelte:head>

<div class="settings-page">
  <div class="settings-container">
    <!-- Profile Section -->
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
          rows="2"
        ></textarea>
      </label>
      
      {#if bio !== initialBio}
        <div class="bio-actions">
          <Button variant="primary" type="submit" loading={isSubmittingBio} size="small">
            Save
          </Button>
        </div>
      {/if}
    </form>

    <!-- Settings sections -->
    <div class="settings-sections">
      <!-- Personal settings -->
      <ModalSection title="Personal" border={false} padding={false}>
        {#if memberships.length > 0}
          <SettingsRow
            label="Notifications"
            description="{memberships.length} rooms"
            icon={iconMessages}
            onclick={() => showNotificationsModal = true}
          />
        {/if}

        {#if transferUrl}
          <SettingsRow
            label="Login on another device"
            description="Transfer your session"
            icon={iconTransfer}
            onclick={() => showTransferModal = true}
          />
        {/if}
      </ModalSection>

      <!-- Organization settings -->
      <ModalSection title={account?.name || "Organization"} border={false} padding={false}>
        {#if canAdminister}
          <SettingsRow
            label="Room creation"
            description={restrictRoomCreation ? "Only admins can create rooms" : "Everyone can create rooms"}
            icon={iconLock}
          >
            <Toggle
              checked={restrictRoomCreation}
              onchange={handleRestrictRoomCreationToggle}
              ariaLabel="Restrict room creation to administrators"
            />
          </SettingsRow>
        {/if}

        <SettingsRow
          label="Members"
          description="{administrators.length} admins, {members.length} members"
          icon={iconPerson}
          href="/account/users"
        />
        
        <SettingsRow
          label="Invite people"
          description="Share a link to invite new members"
          icon={iconPersonAdd}
          href="/account/invite"
        />

        {#if canAdminister}
          <SettingsRow
            label="Organization settings"
            description="Change name and logo"
            icon={iconOffice}
            onclick={() => document.getElementById('org-settings-section')?.scrollIntoView({ behavior: 'smooth' })}
          />
        {/if}
      </ModalSection>

      <!-- Organization branding (admin only) -->
      {#if canAdminister}
        <div id="org-settings-section">
          <ModalSection title="Organization branding" border={false} padding={false}>
            <div class="org-branding">
              <label class="logo-upload">
                <img
                  src={logoPreview || logoUrl}
                  alt={account?.name}
                  class="logo-image"
                />
                <input
                  type="file"
                  accept="image/*"
                  onchange={handleLogoChange}
                  class="sr-only"
                />
                <span class="logo-upload-overlay">
                  <img src={iconCamera} alt="" width="20" height="20" />
                </span>
              </label>
              
              <form onsubmit={handleNameSubmit} class="name-form">
                <input
                  type="text"
                  bind:value={accountName}
                  class="name-input"
                  placeholder="Organization Name"
                />
                {#if accountName !== initialAccountName}
                  <Button variant="primary" type="submit" loading={isSubmittingName} size="small">
                    Save
                  </Button>
                {/if}
              </form>
            </div>
          </ModalSection>
        </div>
      {/if}
    </div>

    {#if version}
      <footer class="settings-footer">
        New Internet v{version}
      </footer>
    {/if}
  </div>
</div>

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
            <span class="notification-room-name">{membership.room?.display_name || membership.room?.name}</span>
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
            <span class="notification-room-name">{membership.room?.display_name || membership.room?.name}</span>
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

    <div class="url-box">
      <input
        type="text"
        value={transferUrl}
        readonly
        class="url-input url-input--center"
        onclick={(e) => e.target.select()}
      />
    </div>
    
    <div class="action-buttons">
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

<!-- Delete Confirmation Modal -->
<Modal
  open={!!deleteConfirmUser}
  title="Remove member?"
  size="small"
  onclose={() => deleteConfirmUser = null}
>
  <p class="confirm-text">
    Are you sure you want to remove <strong>{deleteConfirmUser?.name}</strong> from {account?.name}? This action cannot be undone.
  </p>
  
  {#snippet footer()}
    <Button variant="secondary" onclick={() => deleteConfirmUser = null}>
      Cancel
    </Button>
    <Button variant="danger" onclick={confirmDeleteUser}>
      Remove
    </Button>
  {/snippet}
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

  /* Header / Profile section */
  .settings-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding-bottom: 1.5rem;
    margin-bottom: 1rem;
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
    width: 5rem;
    height: 5rem;
    border-radius: 50%;
    object-fit: cover;
    background: var(--color-bg);
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
    width: 1.5rem;
    height: 1.5rem;
    padding: 0;
    border: 2px solid var(--color-message-bg);
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
    width: 12px;
    height: 12px;
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
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0;
    line-height: 1.2;
  }

  .user-handle {
    font-size: 0.875rem;
    color: var(--color-border-darker);
  }

  /* Bio section */
  .bio-section {
    margin-bottom: 1.5rem;
  }

  .bio-label {
    display: flex;
    flex-direction: column;
    gap: 0.375rem;
  }

  .bio-label-text {
    font-size: 0.75rem;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--color-border-darker);
  }

  .bio-input {
    width: 100%;
    padding: 0.625rem 0.75rem;
    border: 1px solid var(--color-border);
    border-radius: 0.5rem;
    background: var(--color-bg);
    font-family: inherit;
    font-size: 0.875rem;
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
    margin-top: 0.5rem;
  }

  /* Sections */
  .settings-sections {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .settings-footer {
    text-align: center;
    padding-top: 1.5rem;
    margin-top: 1.5rem;
    font-size: 0.6875rem;
    color: var(--color-border-darker);
  }

  /* Organization branding */
  .org-branding {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    background: var(--color-bg);
    border-radius: 0.5rem;
  }

  .logo-upload {
    position: relative;
    cursor: pointer;
  }

  .logo-image {
    width: 4rem;
    height: 4rem;
    border-radius: 0.75rem;
    object-fit: cover;
    background: var(--color-message-bg);
  }

  .logo-upload-overlay {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: oklch(var(--lch-always-black) / 0.5);
    border-radius: 0.75rem;
    opacity: 0;
    transition: opacity 150ms ease;
  }

  .logo-upload:hover .logo-upload-overlay {
    opacity: 1;
  }

  .logo-upload-overlay img {
    filter: invert(1);
  }

  .name-form {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .name-input {
    font-size: 1rem;
    font-weight: 500;
    text-align: center;
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
    padding: 0.25rem 0.5rem;
    transition: border-color 150ms ease;
  }

  .name-input:focus {
    outline: none;
    border-bottom-color: var(--color-selected-dark);
  }

  /* Modal shared styles */
  .url-box {
    background: var(--color-bg);
    border-radius: 0.5rem;
    padding: 0.75rem;
  }

  .url-input {
    width: 100%;
    background: transparent;
    border: none;
    font-size: 0.8125rem;
    font-family: monospace;
    color: var(--color-text);
  }

  .url-input:focus {
    outline: none;
  }

  .url-input--center {
    text-align: center;
  }

  .action-buttons {
    display: flex;
    gap: 0.5rem;
    justify-content: center;
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
    font-size: 0.6875rem;
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
    padding: 0.5rem 0.75rem;
    background: var(--color-bg);
    border-radius: 0.5rem;
  }

  .notification-room-name {
    font-weight: 500;
    font-size: 0.875rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    flex: 1;
    min-width: 0;
  }

  .notification-select {
    padding: 0.25rem 0.5rem;
    border: 1px solid var(--color-border);
    border-radius: 0.375rem;
    background: var(--color-message-bg);
    font-size: 0.75rem;
    cursor: pointer;
    flex-shrink: 0;
  }

  .notification-select:focus {
    outline: none;
    border-color: var(--color-selected-dark);
  }

  /* Confirm Modal */
  .confirm-text {
    margin: 0;
    line-height: 1.5;
  }
</style>
