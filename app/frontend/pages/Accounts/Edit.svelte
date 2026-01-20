<script>
  import { onMount, onDestroy, mount, unmount, untrack } from "svelte";
  import { router } from "@inertiajs/svelte";
  import AccountNav from "../../components/AccountNav.svelte";

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
    // Mount nav into the #nav element
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
      try {
        unmount(navInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      navInstance = null;
    }
  });

  // Split users into admins and members
  let administrators = $derived(users.filter((u) => u.role === "administrator"));
  let members = $derived(users.filter((u) => u.role !== "administrator"));

  // Form state - initialized from props (intentionally capturing initial values)
  const initialAccountName = untrack(() => account?.name ?? "");
  const initialRestrictRoomCreation = untrack(
    () => account?.settings?.restrict_room_creation_to_administrators ?? false
  );
  let accountName = $state(initialAccountName);
  let isSubmitting = $state(false);
  let logoPreview = $state(null);
  let restrictRoomCreation = $state(initialRestrictRoomCreation);

  function handleLogoChange(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    // Preview
    const reader = new FileReader();
    reader.onload = (e) => {
      logoPreview = e.target.result;
    };
    reader.readAsDataURL(file);

    // Submit
    const formData = new FormData();
    formData.append("account[logo]", file);

    router.patch("/account", formData, {
      forceFormData: true,
      preserveScroll: true,
      onFinish: () => {
        logoPreview = null;
      },
    });
  }

  function handleDeleteLogo() {
    router.delete("/account/logo", {
      preserveScroll: true,
    });
  }

  function handleNameSubmit(event) {
    event.preventDefault();
    isSubmitting = true;

    router.patch(
      "/account",
      { account: { name: accountName } },
      {
        preserveScroll: true,
        onFinish: () => {
          isSubmitting = false;
        },
      }
    );
  }

  function handleRestrictRoomCreationToggle() {
    const newValue = !restrictRoomCreation;
    restrictRoomCreation = newValue;

    router.put(
      "/account",
      {
        account: {
          settings: {
            restrict_room_creation_to_administrators: newValue,
          },
        },
      },
      { preserveScroll: true }
    );
  }

  function handleUserRoleToggle(user) {
    const newRole = user.role === "administrator" ? "member" : "administrator";
    router.patch(
      `/account/users/${user.id}`,
      { user: { role: newRole } },
      { preserveScroll: true }
    );
  }

  function handleDeleteUser(user) {
    if (
      confirm(
        "Are you sure you want to permanently remove this person from the account? This can't be undone."
      )
    ) {
      router.delete(`/account/users/${user.id}`, {
        preserveScroll: true,
      });
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
    router.visit("/profile");
  }
</script>

<svelte:head>
  <title>Account Settings</title>
</svelte:head>

<section
  class="panel txt-align-center flex flex-column gap"
  style="view-transition-name: account-settings"
>
  {#if canAdminister}
    <!-- Logo upload for admins -->
    <div class="align-center center avatar__form gap">
      <label class="btn input--file">
        <img
          src={iconCamera}
          aria-hidden="true"
          width="20"
          height="20"
          alt=""
        />
        <input
          type="file"
          accept="image/*"
          class="input"
          style="display: none"
          onchange={handleLogoChange}
        />
        <span class="for-screen-reader">Upload logo</span>
      </label>

      <label class="btn avatar input--file account-logo txt-xx-large">
        <img
          src={logoPreview || logoUrl}
          role="presentation"
          width="48"
          height="48"
          alt=""
        />
        <input
          type="file"
          accept="image/*"
          class="input"
          style="display: none"
          onchange={handleLogoChange}
        />
        <span class="for-screen-reader">Upload logo</span>
      </label>

      {#if account?.has_logo}
        <button
          type="button"
          class="btn btn--negative txt-small avatar__delete-btn"
          onclick={handleDeleteLogo}
        >
          <img
            src={iconMinus}
            aria-hidden="true"
            width="20"
            height="20"
            alt=""
          />
          <span class="for-screen-reader">Delete logo</span>
        </button>
      {/if}
    </div>

    <!-- Account name form -->
    <form onsubmit={handleNameSubmit} class="flex flex-column gap">
      <div class="flex align-center gap">
        <span class="btn btn--disabled">Name</span>
        <label class="flex align-center gap flex-item-grow">
          <input
            type="text"
            bind:value={accountName}
            class="input txt-large"
            autocomplete="off"
            placeholder="Organization Name"
          />
        </label>
        <button
          type="submit"
          class="btn btn--reversed center"
          disabled={isSubmitting}
        >
          <img
            src={iconCheck}
            aria-hidden="true"
            width="20"
            height="20"
            alt=""
          />
          <span class="for-screen-reader">Save changes</span>
        </button>
      </div>
    </form>

    <!-- Room creation restriction toggle -->
    <div
      class="margin-block-start pad-block pad-inline-double fill-shade border-radius"
    >
      <div class="flex align-center gap center">
        <div class="flex-item-grow flex align-center gap txt-align-start">
          <img
            src={iconCrown}
            class="colorize--black"
            aria-hidden="true"
            width="18"
            height="18"
            alt=""
          />
          Must be admin to create new rooms
        </div>
        <label class="switch">
          <input
            type="checkbox"
            class="switch__input"
            checked={restrictRoomCreation}
            onchange={handleRestrictRoomCreationToggle}
          />
          <span class="switch__btn round"></span>
          <span class="for-screen-reader">
            Must be admin to create new rooms
          </span>
        </label>
      </div>
    </div>
  {:else}
    <!-- Non-admin view -->
    <div class="account-logo txt-xx-large center">
      <img src={logoUrl} role="presentation" width="48" height="48" alt="" />
    </div>
    <h1 class="flex-item-grow txt-x-large">{account?.name}</h1>
  {/if}

  <!-- Invite section -->
  <div class="margin-block pad-inline pad-block-start fill-shade border-radius">
    <div class="flex flex-column align-center gap">
      <label class="flex flex-column gap full-width" style="--row-gap: 0.5em">
        <strong id="invite_label" class="invite-label"
          >Share to invite more people</strong
        >
        <span class="flex align-center gap input input--actor fill-white">
          <img
            src={iconPersonAdd}
            aria-hidden="true"
            width="20"
            height="20"
            alt=""
            class="colorize--black"
          />
          <input
            type="text"
            class="input"
            id="invite_url"
            value={joinUrl}
            aria-labelledby="invite_label"
            readonly
          />
        </span>
      </label>

      <div class="flex align-center gap">
        <button type="button" class="btn" onclick={() => openQrCode(joinUrl)}>
          <span class="for-screen-reader">Show join link QR code</span>
          <img
            src={iconQrCode}
            aria-hidden="true"
            width="20"
            height="20"
            alt=""
            class="colorize--black"
          />
        </button>

        <button
          type="button"
          class="btn"
          onclick={() => copyToClipboard(joinUrl)}
        >
          <span class="for-screen-reader">Copy join link</span>
          <img
            src={iconCopyPaste}
            aria-hidden="true"
            width="20"
            height="20"
            alt=""
            class="colorize--black"
          />
        </button>

        <button
          type="button"
          class="btn"
          onclick={() =>
            shareUrl(
              joinUrl,
              "Link to join New Internet",
              "Hit this link to join me and start chatting."
            )}
        >
          <span class="for-screen-reader">Share join link</span>
          <img
            src={iconShare}
            aria-hidden="true"
            width="20"
            height="20"
            alt=""
            class="colorize--black"
          />
        </button>

        {#if canAdminister}
          <button
            type="button"
            class="btn btn--regenerate"
            onclick={handleRegenerateJoinCode}
          >
            <img
              src={iconRefresh}
              aria-hidden="true"
              width="20"
              height="20"
              alt=""
              class="colorize--black"
            />
            <span class="for-screen-reader">Regenerate join link</span>
          </button>
        {/if}
      </div>
    </div>

    <hr class="margin-block separator full-width" style="--border-style: solid" />

    <!-- Users list -->
    <menu class="flex flex-column gap margin-none pad">
      {#each administrators as user (user.id)}
        <li class="flex align-center gap margin-none" class:banned={user.status === "banned"}>
          <figure class="avatar flex-item-no-shrink" style="--avatar-size: 3.75ch;">
            <img src={user.avatar_url} loading="lazy" width="48" height="48" alt="" />
          </figure>
          <div class="min-width">
            <div class="overflow-ellipsis fill-shade">
              <strong>{user.name}</strong>
            </div>
          </div>
          <hr class="separator" aria-hidden="true" />

          {#if canAdminister && user.status === "active"}
            {#if !user.is_bot}
              <button
                type="button"
                class="btn txt-small flex-item-no-shrink"
                class:btn--active={user.role === "administrator"}
                onclick={() => handleUserRoleToggle(user)}
                disabled={user.id === currentUser?.id}
              >
                <span class="for-screen-reader"
                  >Role: {user.role === "administrator" ? "Administrator" : "Member"}</span
                >
                <img
                  src={iconCrown}
                  width="20"
                  height="20"
                  aria-hidden="true"
                  alt=""
                />
              </button>
            {/if}

            {#if user.id !== currentUser?.id}
              <button
                type="button"
                class="btn txt-small flex-item-no-shrink btn--negative"
                onclick={() => handleDeleteUser(user)}
              >
                <img
                  src={iconMinus}
                  width="20"
                  height="20"
                  aria-hidden="true"
                  alt=""
                />
                <span class="for-screen-reader">Delete {user.name}</span>
              </button>
            {/if}
          {/if}

          {#if user.id === currentUser?.id}
            <button
              type="button"
              class="btn txt-small flex-item-no-shrink"
              onclick={navigateToProfile}
            >
              <img
                src={iconPencil}
                width="20"
                height="20"
                aria-hidden="true"
                alt=""
              />
              <span class="for-screen-reader">My settings</span>
            </button>
          {/if}
        </li>
      {/each}

      {#if administrators.length > 0 && members.length > 0}
        <hr class="separator full-width" style="--border-style: solid" />
      {/if}

      {#each members as user (user.id)}
        <li class="flex align-center gap margin-none" class:banned={user.status === "banned"}>
          <figure class="avatar flex-item-no-shrink" style="--avatar-size: 3.75ch;">
            <img src={user.avatar_url} loading="lazy" width="48" height="48" alt="" />
          </figure>
          <div class="min-width">
            <div class="overflow-ellipsis fill-shade">
              <strong>{user.name}</strong>
            </div>
          </div>
          <hr class="separator" aria-hidden="true" />

          {#if canAdminister && user.status === "active"}
            {#if !user.is_bot}
              <button
                type="button"
                class="btn txt-small flex-item-no-shrink"
                class:btn--active={user.role === "administrator"}
                onclick={() => handleUserRoleToggle(user)}
              >
                <span class="for-screen-reader"
                  >Role: {user.role === "administrator" ? "Administrator" : "Member"}</span
                >
                <img
                  src={iconCrown}
                  width="20"
                  height="20"
                  aria-hidden="true"
                  alt=""
                />
              </button>
            {/if}

            <button
              type="button"
              class="btn txt-small flex-item-no-shrink btn--negative"
              onclick={() => handleDeleteUser(user)}
            >
              <img
                src={iconMinus}
                width="20"
                height="20"
                aria-hidden="true"
                alt=""
              />
              <span class="for-screen-reader">Delete {user.name}</span>
            </button>
          {/if}

          {#if user.id === currentUser?.id}
            <button
              type="button"
              class="btn txt-small flex-item-no-shrink"
              onclick={navigateToProfile}
            >
              <img
                src={iconPencil}
                width="20"
                height="20"
                aria-hidden="true"
                alt=""
              />
              <span class="for-screen-reader">My settings</span>
            </button>
          {/if}
        </li>
      {/each}
    </menu>
  </div>
</section>

{#if version}
  <div class="txt-align-center center margin-block-double txt-subtle">
    New Internet v{version}
  </div>
{/if}
