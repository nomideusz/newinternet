<script>
  let {
    checked = $bindable(false),
    disabled = false,
    onchange = undefined,
    ariaLabel = "",
  } = $props();

  function handleChange(event) {
    checked = event.target.checked;
    onchange?.(checked);
  }
</script>

<label class="toggle" class:toggle--disabled={disabled}>
  <input
    type="checkbox"
    class="toggle__input"
    {checked}
    {disabled}
    onchange={handleChange}
    aria-label={ariaLabel}
  />
  <span class="toggle__track">
    <span class="toggle__thumb"></span>
  </span>
</label>

<style>
  .toggle {
    display: inline-flex;
    cursor: pointer;
  }

  .toggle--disabled {
    cursor: not-allowed;
    opacity: 0.5;
  }

  .toggle__input {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }

  .toggle__track {
    position: relative;
    display: inline-flex;
    align-items: center;
    width: 2.75rem;
    height: 1.5rem;
    background: var(--color-border-dark);
    border-radius: 0.75rem;
    transition: background-color 200ms ease;
  }

  .toggle__input:checked + .toggle__track {
    background: var(--color-selected-dark);
  }

  .toggle__input:focus-visible + .toggle__track {
    outline: 2px solid var(--color-selected-dark);
    outline-offset: 2px;
  }

  .toggle__thumb {
    position: absolute;
    left: 0.125rem;
    width: 1.25rem;
    height: 1.25rem;
    background: var(--color-bg);
    border-radius: 50%;
    box-shadow: 0 1px 3px oklch(var(--lch-always-black) / 0.2);
    transition: transform 200ms cubic-bezier(0.4, 0, 0.2, 1);
  }

  .toggle__input:checked + .toggle__track .toggle__thumb {
    transform: translateX(1.25rem);
  }
</style>
