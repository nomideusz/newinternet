<script>
  // Props passed by InertiaX Frame
  let { router, message, timestamp, user = null } = $props();

  let clickCount = $state(0);

  function handleClick() {
    clickCount++;
  }

  function navigateDemo() {
    // Inertia navigation - no full page reload!
    router.reload({ only: ["timestamp"] });
  }
</script>

<div class="demo-page">
  <h1>Inertia + Svelte Demo</h1>

  <div class="demo-card">
    <h2>Server Props</h2>
    <p><strong>Message:</strong> {message}</p>
    <p><strong>Timestamp:</strong> {timestamp}</p>
    {#if user}
      <p><strong>User:</strong> {user.name}</p>
    {/if}
  </div>

  <div class="demo-card">
    <h2>Svelte Reactivity</h2>
    <p>Click count: <strong>{clickCount}</strong></p>
    <button onclick={handleClick} class="btn btn--primary"> Click me! </button>
  </div>

  <div class="demo-card">
    <h2>Inertia Navigation</h2>
    <p>This reloads only the timestamp prop without a full page refresh:</p>
    <button onclick={navigateDemo} class="btn btn--secondary">
      Reload timestamp
    </button>
  </div>

  <div class="demo-card">
    <h2>What This Proves</h2>
    <ul>
      <li>Rails controllers can pass props to Svelte components</li>
      <li>Svelte reactivity works correctly</li>
      <li>Inertia handles navigation without page reloads</li>
      <li>Your existing CSS styles are applied</li>
    </ul>
  </div>
</div>

<style>
  .demo-page {
    max-width: 600px;
    margin: 2rem auto;
    padding: 1rem;
  }

  .demo-card {
    background: var(--panel-background, #f5f5f5);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 1rem;
  }

  h1 {
    margin-bottom: 1.5rem;
  }

  h2 {
    margin-bottom: 0.5rem;
    font-size: 1.1rem;
  }

  ul {
    margin: 0;
    padding-left: 1.5rem;
  }

  li {
    margin: 0.25rem 0;
  }

  button {
    margin-top: 0.5rem;
  }
</style>
