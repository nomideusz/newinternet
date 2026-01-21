<script>
  let {
    variant = "secondary", // "primary", "secondary", "ghost", "danger"
    size = "default", // "small", "default", "large"
    fullWidth = false,
    disabled = false,
    loading = false,
    type = "button",
    href = undefined,
    icon = undefined,
    iconPosition = "left",
    onclick = undefined,
    children,
  } = $props();

  const Tag = $derived(href ? "a" : "button");
</script>

<svelte:element
  this={Tag}
  class="btn-modern"
  class:btn-modern--primary={variant === "primary"}
  class:btn-modern--secondary={variant === "secondary"}
  class:btn-modern--ghost={variant === "ghost"}
  class:btn-modern--danger={variant === "danger"}
  class:btn-modern--small={size === "small"}
  class:btn-modern--large={size === "large"}
  class:btn-modern--full-width={fullWidth}
  class:btn-modern--loading={loading}
  class:btn-modern--icon-only={icon && !children}
  role={href ? "link" : "button"}
  {type}
  {href}
  {onclick}
  disabled={disabled || loading}
  aria-busy={loading}
>
  {#if loading}
    <span class="btn-modern__spinner" aria-hidden="true">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <circle cx="12" cy="12" r="10" stroke-opacity="0.25"></circle>
        <path d="M12 2a10 10 0 0 1 10 10" stroke-linecap="round"></path>
      </svg>
    </span>
  {/if}
  
  {#if icon && iconPosition === "left" && !loading}
    <span class="btn-modern__icon">
      <img src={icon} alt="" aria-hidden="true" width="16" height="16" />
    </span>
  {/if}
  
  {#if children}
    <span class="btn-modern__label">
      {@render children()}
    </span>
  {/if}
  
  {#if icon && iconPosition === "right" && !loading}
    <span class="btn-modern__icon">
      <img src={icon} alt="" aria-hidden="true" width="16" height="16" />
    </span>
  {/if}
</svelte:element>

<style>
  .btn-modern {
    --btn-height: 2.5rem;
    --btn-padding: 0 1rem;
    --btn-font-size: 0.875rem;
    --btn-radius: 0.5rem;
    --btn-gap: 0.5rem;

    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--btn-gap);
    height: var(--btn-height);
    padding: var(--btn-padding);
    border: none;
    border-radius: var(--btn-radius);
    font-family: inherit;
    font-size: var(--btn-font-size);
    font-weight: 500;
    line-height: 1;
    text-decoration: none;
    cursor: pointer;
    transition: 
      background-color 150ms ease,
      color 150ms ease,
      box-shadow 150ms ease,
      transform 100ms ease;
  }

  .btn-modern:focus-visible {
    outline: 2px solid var(--color-selected-dark);
    outline-offset: 2px;
  }

  .btn-modern:active:not(:disabled) {
    transform: scale(0.98);
  }

  .btn-modern:disabled {
    cursor: not-allowed;
    opacity: 0.5;
  }

  /* === SIZE VARIANTS === */
  .btn-modern--small {
    --btn-height: 2rem;
    --btn-padding: 0 0.75rem;
    --btn-font-size: 0.8125rem;
    --btn-gap: 0.375rem;
  }

  .btn-modern--large {
    --btn-height: 3rem;
    --btn-padding: 0 1.5rem;
    --btn-font-size: 1rem;
    --btn-gap: 0.625rem;
  }

  .btn-modern--icon-only {
    --btn-padding: 0;
    width: var(--btn-height);
  }

  .btn-modern--full-width {
    width: 100%;
  }

  /* === COLOR VARIANTS === */
  .btn-modern--primary {
    background: var(--color-text);
    color: var(--color-text-reversed);
  }

  .btn-modern--primary:hover:not(:disabled) {
    background: oklch(from var(--color-text) calc(l + 0.1) c h);
  }

  .btn-modern--primary .btn-modern__icon img {
    filter: invert(1);
  }

  .btn-modern--secondary {
    background: var(--color-message-bg);
    color: var(--color-text);
  }

  .btn-modern--secondary:hover:not(:disabled) {
    background: var(--color-border);
  }

  .btn-modern--ghost {
    background: transparent;
    color: var(--color-text);
  }

  .btn-modern--ghost:hover:not(:disabled) {
    background: var(--color-message-bg);
  }

  .btn-modern--danger {
    background: var(--color-negative);
    color: white;
  }

  .btn-modern--danger:hover:not(:disabled) {
    background: oklch(from var(--color-negative) calc(l - 0.05) c h);
  }

  .btn-modern--danger .btn-modern__icon img {
    filter: invert(1);
  }

  /* === ELEMENTS === */
  .btn-modern__icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .btn-modern__label {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .btn-modern__spinner {
    display: flex;
    align-items: center;
    justify-content: center;
    animation: btn-spin 0.8s linear infinite;
  }

  @keyframes btn-spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }

  .btn-modern--loading .btn-modern__label,
  .btn-modern--loading .btn-modern__icon {
    opacity: 0;
  }
</style>
