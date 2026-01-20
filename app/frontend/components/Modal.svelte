<script>
  import { onMount, onDestroy, tick } from "svelte";
  import iconRemove from "images/remove.svg";

  let {
    open = $bindable(false),
    title = "",
    subtitle = "",
    size = "default", // "small", "default", "large", "fullscreen"
    closeable = true,
    closeOnBackdrop = true,
    closeOnEscape = true,
    showHeader = true,
    onclose = undefined,
    children,
    footer,
  } = $props();

  let dialogRef = $state(null);
  let previousActiveElement = null;

  // Handle open/close
  $effect(() => {
    if (open) {
      openModal();
    } else {
      closeModal();
    }
  });

  async function openModal() {
    previousActiveElement = document.activeElement;
    await tick();
    if (dialogRef) {
      dialogRef.showModal();
      // Focus first focusable element
      const focusable = dialogRef.querySelector(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      if (focusable) focusable.focus();
    }
    document.body.style.overflow = "hidden";
  }

  function closeModal() {
    if (dialogRef?.open) {
      dialogRef.close();
    }
    document.body.style.overflow = "";
    if (previousActiveElement) {
      previousActiveElement.focus();
    }
  }

  function handleClose() {
    if (!closeable) return;
    open = false;
    onclose?.();
  }

  function handleBackdropClick(event) {
    if (closeOnBackdrop && event.target === dialogRef) {
      handleClose();
    }
  }

  function handleKeydown(event) {
    if (event.key === "Escape" && closeOnEscape) {
      event.preventDefault();
      handleClose();
    }
  }

  onMount(() => {
    if (closeOnEscape) {
      document.addEventListener("keydown", handleKeydown);
    }
  });

  onDestroy(() => {
    document.removeEventListener("keydown", handleKeydown);
    document.body.style.overflow = "";
  });
</script>

<!-- svelte-ignore a11y_click_events_have_key_events a11y_no_noninteractive_element_interactions -->
<dialog
  bind:this={dialogRef}
  class="modal"
  class:modal--small={size === "small"}
  class:modal--large={size === "large"}
  class:modal--fullscreen={size === "fullscreen"}
  onclick={handleBackdropClick}
  aria-labelledby={title ? "modal-title" : undefined}
>
  <div class="modal__container">
    {#if showHeader}
      <header class="modal__header">
        <div class="modal__header-content">
          {#if title}
            <h2 id="modal-title" class="modal__title">{title}</h2>
          {/if}
          {#if subtitle}
            <p class="modal__subtitle">{subtitle}</p>
          {/if}
        </div>
        {#if closeable}
          <button
            type="button"
            class="modal__close"
            onclick={handleClose}
            aria-label="Close modal"
          >
            <img src={iconRemove} alt="" aria-hidden="true" width="16" height="16" class="colorize--black" />
          </button>
        {/if}
      </header>
    {/if}

    <div class="modal__body">
      {@render children?.()}
    </div>

    {#if footer}
      <footer class="modal__footer">
        {@render footer()}
      </footer>
    {/if}
  </div>
</dialog>

<style>
  /* === MODAL BASE === */
  .modal {
    --modal-width: min(32rem, calc(100vw - 2rem));
    --modal-max-height: calc(100dvh - 4rem);
    --modal-radius: 0.75rem;
    --modal-padding: 1.5rem;
    --modal-gap: 1.25rem;

    position: fixed;
    inset: 0;
    margin: auto;
    padding: 0;
    border: none;
    background: transparent;
    max-width: 100vw;
    max-height: 100dvh;
    overflow: visible;
  }

  .modal::backdrop {
    background: oklch(0% 0 0 / 0.6);
    backdrop-filter: blur(4px);
    -webkit-backdrop-filter: blur(4px);
  }

  .modal[open] {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  /* === SIZE VARIANTS === */
  .modal--small {
    --modal-width: min(24rem, calc(100vw - 2rem));
  }

  .modal--large {
    --modal-width: min(48rem, calc(100vw - 2rem));
  }

  .modal--fullscreen {
    --modal-width: calc(100vw - 2rem);
    --modal-max-height: calc(100dvh - 2rem);
    --modal-radius: 0.5rem;
  }

  /* === CONTAINER === */
  .modal__container {
    display: flex;
    flex-direction: column;
    width: var(--modal-width);
    max-height: var(--modal-max-height);
    background: var(--color-bg);
    border-radius: var(--modal-radius);
    box-shadow:
      0 0 0 1px oklch(var(--lch-always-black) / 0.05),
      0 4px 6px -1px oklch(var(--lch-always-black) / 0.1),
      0 10px 15px -3px oklch(var(--lch-always-black) / 0.15),
      0 20px 25px -5px oklch(var(--lch-always-black) / 0.2);
    overflow: hidden;
  }

  /* === HEADER === */
  .modal__header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
    padding: var(--modal-padding);
    padding-bottom: 0;
    flex-shrink: 0;
  }

  .modal__header-content {
    flex: 1;
    min-width: 0;
  }

  .modal__title {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    line-height: 1.3;
    letter-spacing: -0.01em;
    color: var(--color-text);
  }

  .modal__subtitle {
    margin: 0.375rem 0 0;
    font-size: 0.875rem;
    line-height: 1.5;
    color: var(--color-border-darker);
  }

  .modal__close {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
    padding: 0;
    margin: -0.25rem -0.25rem 0 0;
    border: none;
    border-radius: 0.375rem;
    background: transparent;
    color: var(--color-border-darker);
    cursor: pointer;
    transition: background-color 150ms ease, color 150ms ease;
    flex-shrink: 0;
  }

  .modal__close:hover {
    background: var(--color-message-bg);
    color: var(--color-text);
  }

  .modal__close:focus-visible {
    outline: 2px solid var(--color-selected-dark);
    outline-offset: 2px;
  }

  .modal__close img {
    opacity: 0.6;
    transition: opacity 150ms ease;
  }

  .modal__close:hover img {
    opacity: 1;
  }

  /* === BODY === */
  .modal__body {
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
    padding: var(--modal-padding);
    overscroll-behavior: contain;
  }

  /* Custom scrollbar for modal body */
  .modal__body::-webkit-scrollbar {
    width: 6px;
  }

  .modal__body::-webkit-scrollbar-track {
    background: transparent;
  }

  .modal__body::-webkit-scrollbar-thumb {
    background: var(--color-border-dark);
    border-radius: 3px;
  }

  .modal__body::-webkit-scrollbar-thumb:hover {
    background: var(--color-border-darker);
  }

  /* === FOOTER === */
  .modal__footer {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 0.75rem;
    padding: var(--modal-padding);
    padding-top: 0;
    flex-shrink: 0;
  }

  /* === RESPONSIVE === */
  @media (max-width: 480px) {
    .modal {
      --modal-width: 100vw;
      --modal-max-height: 100dvh;
      --modal-radius: 0;
      --modal-padding: 1.25rem;
    }

    .modal__container {
      border-radius: 0;
      max-height: 100dvh;
    }

    .modal--small,
    .modal--large {
      --modal-width: 100vw;
    }
  }

  /* === ANIMATIONS === */
  @media (prefers-reduced-motion: no-preference) {
    .modal[open]::backdrop {
      animation: modal-backdrop-fade 200ms ease-out;
    }

    .modal[open] .modal__container {
      animation: modal-slide-up 250ms cubic-bezier(0.16, 1, 0.3, 1);
    }
  }

  @keyframes modal-backdrop-fade {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  @keyframes modal-slide-up {
    from {
      opacity: 0;
      transform: translateY(8px) scale(0.98);
    }
    to {
      opacity: 1;
      transform: translateY(0) scale(1);
    }
  }
</style>
