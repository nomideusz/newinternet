<script>
  import { onMount, onDestroy, mount, unmount, untrack } from "svelte";
  import { router } from "@inertiajs/svelte";
  import AccountNav from "../../components/AccountNav.svelte";
  import Modal from "../../components/Modal.svelte";
  import ModalSection from "../../components/ModalSection.svelte";
  import SettingsRow from "../../components/SettingsRow.svelte";
  import Toggle from "../../components/Toggle.svelte";
  import Button from "../../components/Button.svelte";

  import iconCamera from "images/camera.svg";
  import iconMinus from "images/minus.svg";
  import iconCheck from "images/check.svg";
  import iconCrown from "images/crown.svg";
  import iconPersonAdd from "images/person-add.svg";
  import iconQrCode from "images/qr-code.svg";
  import iconCopyPaste from "images/copy-paste.svg";
  import iconShare from "images/share.svg";
  import iconRefresh from "images/refresh.svg";
  import iconPencil from "images/pencil.svg";
  import iconPerson from "images/person.svg";
  import iconSettings from "images/settings.svg";
  import iconTrash from "images/trash.svg";
  import iconLock from "images/lock.svg";

  let {
    page,
    account,
    users = [],
    currentUser,
    canAdminister = false,
    joinUrl,
    logoUrl,
    version,
    sidebar = {},
  } = $props();

  // Track mounted nav instance
  let navInstance = null;

  onMount(() => {
    const navEl = document.getElementById("nav");
    if (navEl) {
      navEl.innerHTML = "";
      navInstance = mount(AccountNav, {
        target: navEl,
        props: { canAdminister },
      });
    }
  });

  onDestroy(() => {
    if (navInstance) {
      try { unmount(navInstance); } catch (e) {}
      navInstance = null;
    }
  });

  // Split users into admins and members
  let administrators = $derived(users.filter((u) => u.role === "administrator"));
  let members = $derived(users.filter((u) => u.role !== "administrator"));

  // Form state
  const initialAccountName = untrack(() => account?.name ?? "");
  const initialRestrictRoomCreation = untrack(
    () => account?.settings?.restrict_room_creation_to_administrators ?? false
  );
  let accountName = $state(initialAccountName);
  let isSubmitting = $state(false);
  let logoPreview = $state(null);
  let restrictRoomCreation = $state(initialRestrictRoomCreation);

  // Modal state
  let showMembersModal = $state(false);
  let showInviteModal = $state(false);
  let deleteConfirmUser = $state(null);

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

  function handleDeleteLogo() {
    router.delete("/account/logo", { preserveScroll: true });
  }

  function handleNameSubmit(event) {
    event.preventDefault();
    isSubmitting = true;
    router.patch(
      "/account",
      { account: { name: accountName } },
      {
        preserveScroll: true,
        onFinish: () => { isSubmitting = false; },
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

  function handleUserRoleToggle(user) {
    const newRole = user.role === "administrator" ? "member" : "administrator";
    router.patch(`/account/users/${user.id}`, { user: { role: newRole } }, { preserveScroll: true });
  }

  function handleDeleteUser(user) {
    deleteConfirmUser = user;
  }

  function confirmDeleteUser() {
    if (deleteConfirmUser) {
      router.delete(`/account/users/${deleteConfirmUser.id}`, { preserveScroll: true });
      deleteConfirmUser = null;
    }
  }

  function handleRegenerateJoinCode() {
    router.post("/account/join_code", {}, { preserveScroll: true });
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

  function navigateToProfile() {
    router.visit("/users/me/profile");
  }
</script>

<svelte:head>
  <title>Account Settings</title>
</svelte:head>

<div class="settings-page">
  <div class="settings-container">
    <!-- Header with logo -->
    <header class="settings-header">
      {#if canAdminister}
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
      {:else}
        <img src={logoUrl} alt={account?.name} class="logo-image" />
      {/if}
      
      {#if canAdminister}
        <form onsubmit={handleNameSubmit} class="name-form">
          <input
            type="text"
            bind:value={accountName}
            class="name-input"
            placeholder="Organization Name"
          />
          {#if accountName !== initialAccountName}
            <Button variant="primary" type="submit" loading={isSubmitting} size="small">
              Save
            </Button>
          {/if}
        </form>
      {:else}
        <h1 class="org-name">{account?.name}</h1>
      {/if}
    </header>

    <!-- Settings sections -->
    <div class="settings-sections">
      {#if canAdminister}
        <ModalSection title="Organization" border={false} padding={false}>
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
        </ModalSection>
      {/if}

      <ModalSection title="People" description="{users.length} members" border={false} padding={false}>
        <SettingsRow
          label="View all members"
          description="{administrators.length} admins, {members.length} members"
          icon={iconPerson}
          onclick={() => showMembersModal = true}
        />
        
        <SettingsRow
          label="Invite people"
          description="Share a link to invite new members"
          icon={iconPersonAdd}
          onclick={() => showInviteModal = true}
        />
      </ModalSection>

      <ModalSection title="Your account" border={false} padding={false}>
        <SettingsRow
          label="Edit profile"
          description="Change your name, avatar, and bio"
          icon={iconPencil}
          onclick={navigateToProfile}
        />
      </ModalSection>
    </div>

    {#if version}
      <footer class="settings-footer">
        New Internet v{version}
      </footer>
    {/if}
  </div>
</div>

<!-- Members Modal -->
<Modal
  bind:open={showMembersModal}
  title="Members"
  subtitle="{users.length} people in {account?.name}"
  size="default"
>
  <div class="members-list">
    {#if administrators.length > 0}
      <div class="members-group">
        <h4 class="members-group-title">Administrators</h4>
        {#each administrators as user (user.id)}
          <div class="member-item">
            <figure class="member-avatar">
              <img src={user.avatar_url} alt="" />
            </figure>
            <div class="member-info">
              <span class="member-name">{user.name}</span>
              {#if user.id === currentUser?.id}
                <span class="member-badge">You</span>
              {/if}
            </div>
            {#if canAdminister && user.id !== currentUser?.id && !user.is_bot}
              <div class="member-actions">
                <button
                  type="button"
                  class="member-action-btn"
                  onclick={() => handleUserRoleToggle(user)}
                  title="Remove admin"
                >
                  <img src={iconCrown} alt="" width="16" height="16" class="colorize--black" />
                </button>
                <button
                  type="button"
                  class="member-action-btn member-action-btn--danger"
                  onclick={() => handleDeleteUser(user)}
                  title="Remove from organization"
                >
                  <img src={iconTrash} alt="" width="16" height="16" />
                </button>
              </div>
            {/if}
          </div>
        {/each}
      </div>
    {/if}

    {#if members.length > 0}
      <div class="members-group">
        <h4 class="members-group-title">Members</h4>
        {#each members as user (user.id)}
          <div class="member-item">
            <figure class="member-avatar">
              <img src={user.avatar_url} alt="" />
            </figure>
            <div class="member-info">
              <span class="member-name">{user.name}</span>
              {#if user.id === currentUser?.id}
                <span class="member-badge">You</span>
              {/if}
            </div>
            {#if canAdminister && !user.is_bot}
              <div class="member-actions">
                <button
                  type="button"
                  class="member-action-btn"
                  onclick={() => handleUserRoleToggle(user)}
                  title="Make admin"
                >
                  <img src={iconCrown} alt="" width="16" height="16" class="colorize--black" style="opacity: 0.3" />
                </button>
                <button
                  type="button"
                  class="member-action-btn member-action-btn--danger"
                  onclick={() => handleDeleteUser(user)}
                  title="Remove from organization"
                >
                  <img src={iconTrash} alt="" width="16" height="16" />
                </button>
              </div>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </div>
</Modal>

<!-- Invite Modal -->
<Modal
  bind:open={showInviteModal}
  title="Invite people"
  subtitle="Share this link to invite new members"
  size="small"
>
  <div class="invite-content">
    <div class="invite-url-box">
      <input
        type="text"
        value={joinUrl}
        readonly
        class="invite-url-input"
        onclick={(e) => e.target.select()}
      />
    </div>
    
    <div class="invite-actions">
      <Button variant="secondary" onclick={() => openQrCode(joinUrl)} icon={iconQrCode}>
        QR Code
      </Button>
      <Button variant="secondary" onclick={() => copyToClipboard(joinUrl)} icon={iconCopyPaste}>
        Copy
      </Button>
      <Button variant="secondary" onclick={() => shareUrl(joinUrl, "Join link", "Join me on New Internet")} icon={iconShare}>
        Share
      </Button>
    </div>

    {#if canAdminister}
      <div class="invite-regenerate">
        <button type="button" class="regenerate-btn" onclick={handleRegenerateJoinCode}>
          <img src={iconRefresh} alt="" width="14" height="14" class="colorize--black" />
          Generate new link
        </button>
        <p class="regenerate-hint">This will invalidate the current link</p>
      </div>
    {/if}
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
  }

  .settings-container {
    width: 100%;
    max-width: 32rem;
  }

  /* Header */
  .settings-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding-bottom: 2rem;
    margin-bottom: 1.5rem;
    border-bottom: 1px solid var(--color-border);
  }

  .logo-upload {
    position: relative;
    cursor: pointer;
  }

  .logo-image {
    width: 5rem;
    height: 5rem;
    border-radius: 1rem;
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
    border-radius: 1rem;
    opacity: 0;
    transition: opacity 150ms ease;
  }

  .logo-upload:hover .logo-upload-overlay {
    opacity: 1;
  }

  .logo-upload-overlay img {
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

  .name-form {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .name-input {
    font-size: 1.25rem;
    font-weight: 600;
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

  .org-name {
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0;
  }

  /* Sections */
  .settings-sections {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .settings-footer {
    text-align: center;
    padding-top: 2rem;
    margin-top: 2rem;
    font-size: 0.75rem;
    color: var(--color-border-darker);
  }

  /* Members Modal */
  .members-list {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .members-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .members-group-title {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--color-border-darker);
    margin: 0 0 0.25rem;
  }

  .member-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.5rem;
    margin: 0 -0.5rem;
    border-radius: 0.5rem;
  }

  .member-item:hover {
    background: var(--color-message-bg);
  }

  .member-avatar {
    width: 2.5rem;
    height: 2.5rem;
    margin: 0;
    flex-shrink: 0;
  }

  .member-avatar img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
  }

  .member-info {
    flex: 1;
    min-width: 0;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .member-name {
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .member-badge {
    font-size: 0.6875rem;
    font-weight: 500;
    padding: 0.125rem 0.375rem;
    background: var(--color-selected);
    color: var(--color-selected-dark);
    border-radius: 0.25rem;
  }

  .member-actions {
    display: flex;
    gap: 0.25rem;
    opacity: 0;
    transition: opacity 150ms ease;
  }

  .member-item:hover .member-actions {
    opacity: 1;
  }

  .member-action-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
    padding: 0;
    border: none;
    border-radius: 0.375rem;
    background: transparent;
    cursor: pointer;
    transition: background-color 150ms ease;
  }

  .member-action-btn:hover {
    background: var(--color-border);
  }

  .member-action-btn--danger:hover {
    background: oklch(var(--lch-red) / 0.15);
  }

  .member-action-btn--danger img {
    filter: none;
    opacity: 0.6;
  }

  .member-action-btn--danger:hover img {
    opacity: 1;
  }

  /* Invite Modal */
  .invite-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .invite-url-box {
    background: var(--color-message-bg);
    border-radius: 0.5rem;
    padding: 0.75rem;
  }

  .invite-url-input {
    width: 100%;
    background: transparent;
    border: none;
    font-size: 0.875rem;
    font-family: monospace;
    color: var(--color-text);
  }

  .invite-url-input:focus {
    outline: none;
  }

  .invite-actions {
    display: flex;
    gap: 0.5rem;
    justify-content: center;
  }

  .invite-regenerate {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.25rem;
    padding-top: 0.5rem;
    border-top: 1px solid var(--color-border);
    margin-top: 0.5rem;
  }

  .regenerate-btn {
    display: flex;
    align-items: center;
    gap: 0.375rem;
    padding: 0.375rem 0.75rem;
    border: none;
    background: transparent;
    font-size: 0.8125rem;
    color: var(--color-border-darker);
    cursor: pointer;
    border-radius: 0.25rem;
    transition: color 150ms ease, background-color 150ms ease;
  }

  .regenerate-btn:hover {
    color: var(--color-text);
    background: var(--color-message-bg);
  }

  .regenerate-hint {
    font-size: 0.6875rem;
    color: var(--color-border-darker);
    margin: 0;
  }

  /* Confirm Modal */
  .confirm-text {
    margin: 0;
    line-height: 1.5;
  }
</style>
