<script>
  import { router } from "@inertiajs/svelte";

  let { currentUser } = $props();

  function navigateToSettings(e) {
    e.preventDefault();
    router.visit("/account/edit");
  }
</script>

{#if currentUser}
  <a
    href="/account/edit"
    class="btn avatar navbar__avatar flex-item-no-shrink"
    onclick={navigateToSettings}
  >
    <img
      src={currentUser.avatar_url}
      width="40"
      height="40"
      aria-hidden="true"
      alt=""
      style="view-transition-name: avatar-{currentUser.id}"
    />
    <span class="for-screen-reader">Settings</span>
  </a>
{/if}
