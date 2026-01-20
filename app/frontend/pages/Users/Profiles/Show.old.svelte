<script>
  import { onMount, onDestroy, mount, unmount, untrack } from "svelte";
  import { router } from "@inertiajs/svelte";
  import ProfileNav from "../../../components/ProfileNav.svelte";

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
    // Mount nav into the #nav element
    const navEl = document.getElementById("nav");
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
      try {
        unmount(navInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      navInstance = null;
    }
  });

  // Form state - initialized once from props (intentionally capturing initial value)
  const initialBio = untrack(() => currentUser?.bio ?? "");
  let bio = $state(initialBio);
  let isSubmitting = $state(false);
  let avatarPreview = $state(null);
  let avatarFileInput = $state(null);

  // Split memberships
  let directMemberships = $derived(
    memberships.filter((m) => m.room.type === "direct")
  );
  let sharedMemberships = $derived(
    memberships.filter((m) => m.room.type !== "direct")
  );

  function handleAvatarChange(event) {
    const file = event.target.files?.[0];
    if (!file) return;

    // Preview
    const reader = new FileReader();
    reader.onload = (e) => {
      avatarPreview = e.target.result;
    };
    reader.readAsDataURL(file);

    // Submit
    const formData = new FormData();
    formData.append("user[avatar]", file);

    router.post("/profile", formData, {
      forceFormData: true,
      preserveScroll: true,
      onFinish: () => {
        avatarPreview = null;
      },
    });
  }

  function handleDeleteAvatar() {
    router.delete(`/users/${currentUser.id}/avatar`, {
      preserveScroll: true,
    });
  }

  function handleBioSubmit(event) {
    event.preventDefault();
    isSubmitting = true;

    router.patch(
      "/profile",
      { user: { bio } },
      {
        preserveScroll: true,
        onFinish: () => {
          isSubmitting = false;
        },
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
</script>

<svelte:head>
  <title>{currentUser?.name} - Profile</title>
</svelte:head>

<section
  class="panel flex flex-column gap"
  style="view-transition-name: avatar-{currentUser?.id}"
>
  <!-- Avatar section -->
  <div class="align-center center avatar__form gap">
    <label class="btn input--file">
      <img src={iconCamera} aria-hidden="true" width="20" height="20" alt="" />
      <input
        type="file"
        accept="image/*"
        class="input"
        style="display: none"
        onchange={handleAvatarChange}
        bind:this={avatarFileInput}
      />
      <span class="for-screen-reader">Upload avatar</span>
    </label>

    <label class="btn avatar input--file txt-xx-large">
      <img
        src={avatarPreview || currentUser?.avatar_url}
        aria-hidden="true"
        width="300"
        height="300"
        alt=""
      />
      <input
        type="file"
        accept="image/*"
        class="input"
        style="display: none"
        onchange={handleAvatarChange}
      />
      <span class="for-screen-reader">Avatar</span>
    </label>

    {#if currentUser?.has_avatar}
      <button
        type="button"
        class="btn btn--negative txt-small avatar__delete-btn"
        onclick={handleDeleteAvatar}
      >
        <img src={iconMinus} aria-hidden="true" width="20" height="20" alt="" />
        <span class="for-screen-reader">Delete avatar</span>
      </button>
    {/if}
  </div>

  <!-- Bio form -->
  <form onsubmit={handleBioSubmit} class="flex flex-column gap">
    <div class="flex align-center gap">
      <span class="btn btn--disabled">@</span>
      <div
        class="flex align-center gap flex-item-grow input input--actor input--disabled"
      >
        <span class="input txt-large flex align-center"
          >{currentUser?.username}</span
        >
        <img
          src={iconPerson}
          aria-hidden="true"
          width="24"
          height="24"
          alt=""
          class="colorize--black"
        />
      </div>
    </div>

    <div class="flex align-start gap">
      <span class="btn btn--disabled">Bio</span>
      <label class="flex align-center gap flex-item-grow input input--actor">
        <textarea
          bind:value={bio}
          class="input txt-large"
          placeholder="A few words about yourself…"
          maxlength="200"
          rows="3"
        ></textarea>
        <img
          src={iconBio}
          aria-hidden="true"
          width="24"
          height="24"
          alt=""
          class="colorize--black"
        />
      </label>
    </div>

    <button
      type="submit"
      class="btn btn--reversed center"
      disabled={isSubmitting}
    >
      <img src={iconCheck} aria-hidden="true" width="20" height="20" alt="" />
      <span>Save changes</span>
    </button>
  </form>

  <!-- Memberships -->
  {#if memberships.length > 0}
    <div class="margin-block pad-inline pad-block fill-shade border-radius">
      <menu class="flex flex-column gap margin-none pad">
        {#each sharedMemberships as membership (membership.id)}
          <li class="flex align-center gap margin-none min-width membership-item">
            <a
              href="/rooms/{membership.room_id}"
              class="overflow-ellipsis fill-shade txt-primary txt-undecorated"
              onclick={(e) => {
                e.preventDefault();
                router.visit(`/rooms/${membership.room_id}`);
              }}
            >
              <strong>{membership.room.display_name}</strong>
            </a>
            <hr class="separator" aria-hidden="true" />
            <select
              class="btn txt-small"
              value={membership.involvement}
              onchange={(e) =>
                handleInvolvementChange(membership.room_id, e.target.value)}
            >
              {#each involvementOptions as opt}
                <option value={opt.value}>{opt.label}</option>
              {/each}
            </select>
          </li>
        {/each}

        {#if directMemberships.length > 0 && sharedMemberships.length > 0}
          <hr class="separator full-width" style="--border-style: solid" />
        {/if}

        {#each directMemberships as membership (membership.id)}
          <li class="flex align-center gap margin-none min-width membership-item">
            <a
              href="/rooms/{membership.room_id}"
              class="overflow-ellipsis fill-shade txt-primary txt-undecorated"
              onclick={(e) => {
                e.preventDefault();
                router.visit(`/rooms/${membership.room_id}`);
              }}
            >
              <strong>{membership.room.display_name}</strong>
            </a>
            <hr class="separator" aria-hidden="true" />
            <select
              class="btn txt-small"
              value={membership.involvement}
              onchange={(e) =>
                handleInvolvementChange(membership.room_id, e.target.value)}
            >
              {#each involvementOptions as opt}
                <option value={opt.value}>{opt.label}</option>
              {/each}
            </select>
          </li>
        {/each}
      </menu>
    </div>
  {/if}

  <!-- Transfer link section -->
  {#if transferUrl}
    <fieldset>
      <legend class="gap">
        <img
          src={iconLaptop}
          aria-hidden="true"
          width="36"
          height="36"
          alt=""
          class="colorize--black"
        />
        <img
          src={iconTransfer}
          aria-hidden="true"
          width="36"
          height="36"
          alt=""
          class="colorize--black"
        />
        <img
          src={iconMobilePhone}
          aria-hidden="true"
          width="36"
          height="36"
          alt=""
          class="colorize--black"
        />
      </legend>

      <div class="flex flex-column gap">
        <label for="session_transfer_url" class="for-screen-reader"
          >Use this link to login automatically on another device</label
        >
        <input
          type="text"
          class="input"
          value={transferUrl}
          id="session_transfer_url"
          readonly
        />

        <div class="flex align-center center gap">
          <button
            type="button"
            class="btn"
            onclick={() => openQrCode(transferUrl)}
          >
            <img
              src={iconQrCode}
              aria-hidden="true"
              width="20"
              height="20"
              alt=""
              class="colorize--black"
            />
            <span class="for-screen-reader">Show auto-login QR code</span>
          </button>

          <button
            type="button"
            class="btn"
            onclick={() => copyToClipboard(transferUrl)}
          >
            <img
              src={iconCopyPaste}
              aria-hidden="true"
              width="20"
              height="20"
              alt=""
              class="colorize--black"
            />
            <span class="for-screen-reader">Copy auto-login link</span>
          </button>

          <button
            type="button"
            class="btn"
            onclick={() =>
              shareUrl(
                transferUrl,
                "Your sign-in link",
                "This is your own private sign-in URL, DO NOT SHARE IT."
              )}
          >
            <img
              src={iconShare}
              aria-hidden="true"
              width="20"
              height="20"
              alt=""
              class="colorize--black"
            />
            <span class="for-screen-reader">Share auto-login link</span>
          </button>
        </div>
      </div>
    </fieldset>
  {/if}
</section>
