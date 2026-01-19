<script>
  import { router } from "@inertiajs/svelte";
  import UserAutocomplete from "../../../components/UserAutocomplete.svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconCheck from "images/check.svg";

  let { page, autocompleteUrl, cancelUrl, currentUser, sidebar = {} } = $props();

  let selectedUsers = $state([]);
  let isSubmitting = $state(false);

  function handleSubmit(event) {
    event.preventDefault();

    if (selectedUsers.length === 0) {
      return;
    }

    isSubmitting = true;
    const userIds = selectedUsers.map((u) => u.id);

    router.post(
      "/rooms/directs",
      { user_ids: userIds },
      {
        onFinish: () => {
          isSubmitting = false;
        },
      },
    );
  }

  function handleCancel() {
    router.visit(cancelUrl);
  }

  function handleKeydown(event) {
    if (event.key === "Escape") {
      handleCancel();
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<div class="directs directs--new flex flex-column gap">
  <form onsubmit={handleSubmit} class="flex gap flex-item-grow">
    <button
      type="button"
      onclick={handleCancel}
      class="btn flex-item-no-shrink"
    >
      <img src={iconArrowLeft} aria-hidden="true" alt="" />
      <span class="for-screen-reader">Cancel changes</span>
    </button>

    <UserAutocomplete
      {autocompleteUrl}
      bind:selectedUsers
      placeholder="Type names to ping someone…"
      required={true}
    />

    <button
      type="submit"
      class="btn btn--reversed flex-item-no-shrink"
      disabled={isSubmitting || selectedUsers.length === 0}
    >
      <img src={iconCheck} aria-hidden="true" alt="" />
      <span class="for-screen-reader">Start Ping</span>
    </button>
  </form>

  <span class="txt-small translucent pad-inline-half center">
    Type names to ping someone…
  </span>
</div>
