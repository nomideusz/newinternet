<script>
  import { Frame } from "inertiax-svelte";
  import niLogo from "images/ni-logo.svg";
  import iconRemove from "images/remove.svg";

  // Layout receives page props directly from Frame's resolveLayout
  // Plus children snippet for the page content
  let {
    children,
    // Page props passed by Frame
    flash = {},
    currentUser = null,
    page: pageInfo = {},
    cancelUrl = null,
    room = null,
    ...rest
  } = $props();

  // Flash messages from shared data (auto-dismiss after 4 seconds)
  let showFlash = $state(true);

  $effect(() => {
    // Reset flash visibility when flash changes
    if (flash?.success || flash?.error) {
      showFlash = true;
      const timer = setTimeout(() => {
        showFlash = false;
      }, 4000);
      return () => clearTimeout(timer);
    }
  });

  // Reactive page title
  let pageTitle = $derived(pageInfo?.title || "New Internet");

  // Determine if this page should show the sidebar based on pageInfo
  let showSidebar = $derived(pageInfo?.bodyClass?.includes("sidebar") ?? true);

  // Modal state - track via global inertia events
  let showModal = $state(false);
  let modalLoaded = $state(false);
  let modalFrame = $state(null);

  // Listen for inertia events to detect modal frame navigation
  $effect(() => {
    function handleBefore(event) {
      const visit = event.detail?.visit;
      const frame = visit?.options?.frame || visit?.frame;

      if (frame === "modal") {
        showModal = true;
        modalLoaded = false;
      }
    }

    function handleFinish(event) {
      const visit = event.detail?.visit;
      const frame = visit?.options?.frame || visit?.frame;

      if (frame === "modal") {
        modalLoaded = true;
      }
    }

    document.addEventListener("inertia:before", handleBefore);
    document.addEventListener("inertia:finish", handleFinish);
    return () => {
      document.removeEventListener("inertia:before", handleBefore);
      document.removeEventListener("inertia:finish", handleFinish);
    };
  });

  function closeModal() {
    showModal = false;
  }

  function handleModalBackdropClick(event) {
    if (event.target === event.currentTarget) {
      closeModal();
    }
  }

  function handleModalKeydown(event) {
    if (event.key === "Escape" && showModal) {
      closeModal();
    }
  }
</script>

<svelte:head>
  <title>{pageTitle}</title>
</svelte:head>

<svelte:window onkeydown={handleModalKeydown} />

{#if showFlash && flash?.success}
  <div class="flash flash--success" role="status">
    {flash.success}
    <button class="flash__dismiss" onclick={() => (showFlash = false)}>×</button
    >
  </div>
{/if}

{#if showFlash && flash?.error}
  <div class="flash flash--error" role="alert">
    {flash.error}
    <button class="flash__dismiss" onclick={() => (showFlash = false)}>×</button
    >
  </div>
{/if}

<nav id="nav">
  <!-- Navigation will be populated by page components -->
</nav>

<main id="main-content">
  {@render children()}
</main>

{#if showSidebar}
  <aside id="sidebar" class="sidebar">
    <Frame name="sidebar" src="/users/me/sidebar">
      <!-- Loading state while sidebar loads -->
      <div class="sidebar-loading">
        <span class="sidebar-loading__spinner"></span>
      </div>
    </Frame>
  </aside>
{/if}

<a href="/" id="app-logo" aria-label="New Internet home page">
  <img src={niLogo} alt="New Internet" />
</a>

<!-- Modal Frame - loads page via InertiaX -->
<!-- svelte-ignore a11y_click_events_have_key_events -->
<div
  class="modal-backdrop"
  class:modal-backdrop--visible={showModal}
  role="presentation"
  onclick={handleModalBackdropClick}
>
  <div class="modal-container" onclick={(e) => e.stopPropagation()}>
    {#if modalLoaded}
      <button class="modal-close" onclick={closeModal} aria-label="Close">
        <img src={iconRemove} alt="" width="16" height="16" />
      </button>
    {/if}
    <Frame name="modal" bind:this={modalFrame} renderLayout={false} closeModal={closeModal}>
      <div class="modal__loading">
        <div class="modal__loading-dots">
          <span class="modal__loading-dot"></span>
          <span class="modal__loading-dot"></span>
          <span class="modal__loading-dot"></span>
        </div>
      </div>
    </Frame>
  </div>
</div>

<style>
  .flash {
    position: fixed;
    top: 1rem;
    left: 50%;
    transform: translateX(-50%);
    padding: 0.75rem 2.5rem 0.75rem 1rem;
    border-radius: 0.5rem;
    z-index: 1000;
    animation: slideDown 0.3s ease-out;
    max-width: 90vw;
  }

  .flash--success {
    background: var(--color-success, #22c55e);
    color: white;
  }

  .flash--error {
    background: var(--color-error, #ef4444);
    color: white;
  }

  .flash__dismiss {
    position: absolute;
    right: 0.5rem;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    color: inherit;
    font-size: 1.25rem;
    cursor: pointer;
    opacity: 0.8;
  }

  .flash__dismiss:hover {
    opacity: 1;
  }

  @keyframes slideDown {
    from {
      opacity: 0;
      transform: translateX(-50%) translateY(-1rem);
    }
    to {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
  }

  .sidebar-loading {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100%;
    padding: 2rem;
  }

  .sidebar-loading__spinner {
    width: 24px;
    height: 24px;
    border: 2px solid var(--color-border, #e5e7eb);
    border-top-color: var(--color-primary, #3b82f6);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  /* Modal styles */
  .modal-backdrop {
    position: fixed !important;
    inset: 0 !important;
    background: oklch(0% 0 0 / 0.7) !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    z-index: 10000 !important;
    padding: 2rem !important;
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
    transition: opacity 0.2s ease-out, visibility 0.2s ease-out;
    overflow: hidden;
  }

  .modal-backdrop.modal-backdrop--visible {
    opacity: 1 !important;
    visibility: visible !important;
    pointer-events: auto;
  }

  .modal-container {
    position: relative;
    width: min(34rem, 90vw);
    max-height: 85vh;
    overflow-y: auto;
    animation: modalSlideUp 0.25s ease-out;
    background: var(--color-bg);
    border-radius: 0.8em;
    border: 1px solid var(--color-border, oklch(0% 0 0 / 0.1));
    padding: 2.5rem;
    box-shadow:
      0 8px 32px oklch(0% 0 0 / 0.3),
      0 16px 48px oklch(0% 0 0 / 0.2);
  }

  .modal-close {
    position: absolute;
    top: -1rem;
    right: -1rem;
    z-index: 10;
    background: #fff;
    border: none;
    color: #000;
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 50%;
    cursor: pointer;
    display: grid;
    place-items: center;
    box-shadow: 0 2px 8px oklch(0% 0 0 / 0.2);
    transition: transform 0.15s ease;
  }

  .modal-close:hover {
    transform: scale(1.05);
  }

  .modal__loading {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    min-width: min(40ch, 80vw);
  }

  .modal__loading-dots {
    display: flex;
    gap: 8px;
    align-items: center;
  }

  .modal__loading-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: var(--color-text, #fff);
    animation: modalDotPulse 1.4s ease-in-out infinite;
  }

  .modal__loading-dot:nth-child(2) {
    animation-delay: 0.2s;
  }

  .modal__loading-dot:nth-child(3) {
    animation-delay: 0.4s;
  }

  @keyframes modalDotPulse {
    0%, 80%, 100% {
      opacity: 0.3;
      transform: scale(0.8);
    }
    40% {
      opacity: 1;
      transform: scale(1);
    }
  }

  @keyframes modalSlideUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
</style>
