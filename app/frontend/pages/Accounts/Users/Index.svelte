<script>
  import { onMount } from "svelte";
  import { router } from "@inertiajs/svelte";
  import { sidebarManager } from "../../../stores/sidebarManager.svelte.js";
  import ModalSection from "../../../components/ModalSection.svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconCrown from "images/crown.svg";
  import iconTrash from "images/trash.svg";

  let {
    page,
    users = [],
    account,
    currentUser,
    canAdminister = false,
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
          <a href="/account/edit" class="btn btn--plain" data-inertia="true">
            <img src="${iconArrowLeft}" alt="" aria-hidden="true" class="icon" />
            <span>Settings</span>
          </a>
        </div>
      `;
    }
  });

  // Split users into admins and members
  let administrators = $derived(users.filter((u) => u.role === "administrator"));
  let members = $derived(users.filter((u) => u.role !== "administrator"));

  let deleteConfirmUser = $state(null);

  function handleUserRoleToggle(user) {
    const newRole = user.role === "administrator" ? "member" : "administrator";
    router.patch(`/account/users/${user.id}`, {
      user: { role: newRole }
    }, {
      preserveScroll: true
    });
  }

  function handleDeleteUser(user) {
    if (deleteConfirmUser?.id === user.id) {
      router.delete(`/account/users/${user.id}`, {
        preserveScroll: true,
        onSuccess: () => {
          deleteConfirmUser = null;
        }
      });
    } else {
      deleteConfirmUser = user;
    }
  }
</script>

<div class="settings-page">
  <div class="settings-content">
    <header class="settings-header">
      <h1 class="settings-title">Members</h1>
      <p class="settings-subtitle">{users.length} people in {account?.name}</p>
    </header>

    <div class="settings-sections">
      {#if administrators.length > 0}
        <ModalSection title="Administrators" border={false} padding={false}>
          <div class="members-list">
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
        </ModalSection>
      {/if}

      {#if members.length > 0}
        <ModalSection title="Members" border={false} padding={false}>
          <div class="members-list">
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
        </ModalSection>
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
    max-width: 40rem;
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

  .settings-sections {
    display: flex;
    flex-direction: column;
    gap: var(--block-space);
  }

  .members-list {
    display: flex;
    flex-direction: column;
  }

  .member-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem;
    border-radius: 0.5rem;
    transition: background-color 150ms ease;
  }

  .member-item:hover {
    background-color: var(--color-bg-secondary);
  }

  .member-avatar {
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 50%;
    overflow: hidden;
    margin: 0;
    flex-shrink: 0;
  }

  .member-avatar img {
    width: 100%;
    height: 100%;
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
    font-size: 0.75rem;
    padding: 0.125rem 0.5rem;
    background-color: var(--color-primary);
    color: white;
    border-radius: 1rem;
    flex-shrink: 0;
  }

  .member-actions {
    display: flex;
    gap: 0.25rem;
    flex-shrink: 0;
  }

  .member-action-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
    border: none;
    background: transparent;
    border-radius: 0.375rem;
    cursor: pointer;
    transition: background-color 150ms ease;
  }

  .member-action-btn:hover {
    background-color: var(--color-bg-tertiary);
  }

  .member-action-btn--danger:hover {
    background-color: oklch(from var(--color-negative) l c h / 0.1);
  }

  .member-action-btn--danger:hover img {
    filter: none;
  }
</style>
