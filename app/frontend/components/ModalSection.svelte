<script>
  let {
    title = "",
    description = "",
    icon = undefined,
    border = true,
    padding = true,
    children,
  } = $props();
</script>

<section 
  class="modal-section"
  class:modal-section--bordered={border}
  class:modal-section--padded={padding}
>
  {#if title || description || icon}
    <header class="modal-section__header">
      {#if icon}
        <div class="modal-section__icon">
          <img src={icon} alt="" aria-hidden="true" width="20" height="20" class="colorize--black" />
        </div>
      {/if}
      <div class="modal-section__header-content">
        {#if title}
          <h3 class="modal-section__title">{title}</h3>
        {/if}
        {#if description}
          <p class="modal-section__description">{description}</p>
        {/if}
      </div>
    </header>
  {/if}
  
  <div class="modal-section__content">
    {@render children?.()}
  </div>
</section>

<style>
  .modal-section {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .modal-section--bordered {
    padding: 1rem;
    background: var(--color-message-bg);
    border-radius: 0.5rem;
  }

  .modal-section--padded + .modal-section--padded {
    margin-top: 0.75rem;
  }

  .modal-section__header {
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
  }

  .modal-section__icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 2.25rem;
    height: 2.25rem;
    background: var(--color-bg);
    border-radius: 0.375rem;
    flex-shrink: 0;
  }

  .modal-section__header-content {
    flex: 1;
    min-width: 0;
  }

  .modal-section__title {
    margin: 0;
    font-size: 0.9375rem;
    font-weight: 600;
    line-height: 1.4;
    color: var(--color-text);
  }

  .modal-section__description {
    margin: 0.125rem 0 0;
    font-size: 0.8125rem;
    line-height: 1.5;
    color: var(--color-border-darker);
  }

  .modal-section__content {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  /* If header exists, add left padding to align content with header text */
  .modal-section__header + .modal-section__content {
    padding-left: 0;
  }
</style>
