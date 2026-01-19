<script>
  import { router } from "@inertiajs/svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconBot from "images/bot.svg";
  import iconArt from "images/art.svg";

  let { canAdminister = false } = $props();

  function handleBack() {
    if (window.history.length > 1) {
      window.history.back();
    } else {
      router.visit("/");
    }
  }

  function navigateToBots() {
    // Bots page is still ERB, so use regular navigation
    window.location.href = "/account/bots";
  }

  function navigateToCustomStyles() {
    // Custom styles page is still ERB, so use regular navigation
    window.location.href = "/account/custom_styles/edit";
  }
</script>

<nav class="nav flex align-center gap">
  <div class="flex-item-justify-start">
    <button type="button" class="btn" onclick={handleBack}>
      <img src={iconArrowLeft} aria-hidden="true" width="20" height="20" alt="" />
      <span class="for-screen-reader">Go back</span>
    </button>
  </div>

  <div class="flex-item-grow"></div>

  {#if canAdminister}
    <div class="flex align-center gap flex-item-justify-end">
      <button
        type="button"
        class="btn"
        style="view-transition-name: chat-bots"
        onclick={navigateToBots}
      >
        <img src={iconBot} aria-hidden="true" width="20" height="20" alt="" />
        <span class="for-screen-reader">Set up chat bots</span>
      </button>

      <button
        type="button"
        class="btn"
        style="view-transition-name: custom-styles"
        onclick={navigateToCustomStyles}
      >
        <img src={iconArt} aria-hidden="true" width="20" height="20" alt="" />
        <span class="for-screen-reader">Custom styles</span>
      </button>
    </div>
  {/if}
</nav>
