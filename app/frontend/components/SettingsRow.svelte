<script>
  let {
    label = "",
    description = "",
    icon = undefined,
    href = undefined,
    onclick = undefined,
    danger = false,
    disabled = false,
    children, // For right-side content like switches, badges
  } = $props();

  let isInteractive = $derived(href || onclick);
  let Tag = $derived(href ? "a" : "button");
</script>

{#if isInteractive}
  <svelte:element
    this={Tag}
    class="settings-row"
    class:settings-row--danger={danger}
    class:settings-row--disabled={disabled}
    role={!href ? "button" : undefined}
    {href}
    onclick={onclick}
    type={!href ? "button" : undefined}
    {disabled}
  >
    {#if icon}
      <span class="settings-row__icon">
        <img src={icon} alt="" aria-hidden="true" width="18" height="18" class="colorize--black" />
      </span>
    {/if}
    <span class="settings-row__content">
      <span class="settings-row__label">{label}</span>
      {#if description}
        <span class="settings-row__description">{description}</span>
      {/if}
    </span>
    {#if children}
      <span class="settings-row__action">
        {@render children()}
      </span>
    {:else if isInteractive}
      <span class="settings-row__chevron">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
      </span>
    {/if}
  </svelte:element>
{:else}
  <div
    class="settings-row"
    class:settings-row--static={true}
    class:settings-row--danger={danger}
  >
    {#if icon}
      <span class="settings-row__icon">
        <img src={icon} alt="" aria-hidden="true" width="18" height="18" class="colorize--black" />
      </span>
    {/if}
    <span class="settings-row__content">
      <span class="settings-row__label">{label}</span>
      {#if description}
        <span class="settings-row__description">{description}</span>
      {/if}
    </span>
    {#if children}
      <span class="settings-row__action">
        {@render children()}
      </span>
    {/if}
  </div>
{/if}

<style>
  .settings-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    width: 100%;
    padding: 0.75rem 1rem;
    margin: 0;
    border: none;
    border-radius: 0.5rem;
    background: var(--color-bg);
    color: var(--color-text);
    text-decoration: none;
    text-align: left;
    cursor: pointer;
    transition: background-color 150ms ease;
  }

  .settings-row:hover:not(.settings-row--static):not(.settings-row--disabled) {
    background: var(--color-border);
  }

  .settings-row:focus-visible {
    outline: 2px solid var(--color-selected-dark);
    outline-offset: 2px;
  }

  .settings-row--static {
    cursor: default;
  }

  .settings-row--danger {
    color: var(--color-negative);
  }

  .settings-row--danger .settings-row__icon img {
    filter: none;
  }

  .settings-row--disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .settings-row__icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2rem;
    height: 2rem;
    background: var(--color-border);
    border-radius: 0.375rem;
    flex-shrink: 0;
  }

  .settings-row--danger .settings-row__icon {
    background: oklch(var(--lch-red) / 0.1);
  }

  .settings-row__content {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
  }

  .settings-row__label {
    font-size: 0.9375rem;
    font-weight: 500;
    line-height: 1.4;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .settings-row__description {
    font-size: 0.8125rem;
    line-height: 1.4;
    color: var(--color-border-darker);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .settings-row--danger .settings-row__description {
    color: inherit;
    opacity: 0.7;
  }

  .settings-row__action {
    flex-shrink: 0;
  }

  .settings-row__chevron {
    flex-shrink: 0;
    color: var(--color-border-darker);
  }
</style>
