<script>
  import { page } from "@inertiajs/svelte";
  import niLogo from "images/ni-logo.svg";
</script>

<svelte:head>
  <title>{$page.props.title || "New Internet"}</title>
</svelte:head>

<div class="inertia-app">
  <nav id="nav">
    <!-- Navigation will be populated by page components -->
  </nav>

  <main id="main-content">
    <slot />
  </main>

  <aside id="sidebar" class="sidebar">
    <!-- Sidebar content -->
  </aside>

  <a href="/" id="app-logo" aria-label="New Internet home page">
    <img src={niLogo} alt="New Internet" />
  </a>
</div>

<style>
  /* Inherit existing styles from your CSS */
  .inertia-app {
    min-height: 100vh;
  }
</style>
