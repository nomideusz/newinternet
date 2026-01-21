<script>
  import { onMount, onDestroy } from "svelte";

  // Props passed from parent
  let {
    children,
    title = "",
    closePath = null,
    cancelUrl = null,
    room = null,
  } = $props();

  // Default close path is to go back, or to the room if available
  let defaultClosePath = $derived(closePath || cancelUrl || room?.path || "/");

  function close() {
    window.location.href = defaultClosePath;
  }

  function handleKeydown(event) {
    if (event.key === "Escape") {
      close();
    }
  }

  function handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      close();
    }
  }

  onMount(() => {
    // Prevent body scroll when modal is open
    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", handleKeydown);
  });

  onDestroy(() => {
    document.body.style.overflow = "";
    window.removeEventListener("keydown", handleKeydown);
  });
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<div class="modal-backdrop" role="presentation" onclick={handleBackdropClick}>
  <div
    class="modal"
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
  >
    <header class="modal__header">
      <h2 id="modal-title" class="modal__title">{title}</h2>
      <button class="modal__close" onclick={close} aria-label="Close modal">
        ×
      </button>
    </header>
    <div class="modal__content">
      {@render children()}
    </div>
  </div>
</div>

<style>
  .modal-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 1rem;
  }

  .modal {
    background: var(--surface-color, #fff);
    border-radius: 8px;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.2);
    max-width: 600px;
    width: 100%;
    max-height: 90vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .modal__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem 1.5rem;
    border-bottom: 1px solid var(--border-color, #e5e5e5);
  }

  .modal__title {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .modal__close {
    background: none;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    padding: 0.25rem 0.5rem;
    line-height: 1;
    color: var(--text-secondary, #666);
    border-radius: 4px;
  }

  .modal__close:hover {
    background: var(--surface-hover, #f0f0f0);
  }

  .modal__content {
    padding: 1.5rem;
    overflow-y: auto;
  }
</style>
