<script>
  import { onMount, onDestroy, mount, unmount } from "svelte";
  import Sidebar from "../components/Sidebar.svelte";

  let {
    children,
    sidebar = null,
    currentUser = null,
  } = $props();

  // Track mounted sidebar instance
  let sidebarInstance = null;
  let lastSidebarEl = null;

  onMount(() => {
    mountSidebar();
  });

  onDestroy(() => {
    unmountSidebar();
  });

  // Re-mount sidebar if props change significantly (e.g., user logs in/out)
  $effect(() => {
    if (sidebar && currentUser) {
      // Only remount if the sidebar element changed or doesn't exist
      const sidebarEl = document.getElementById("sidebar");
      if (sidebarEl && sidebarEl !== lastSidebarEl) {
        unmountSidebar();
        mountSidebar();
      }
    }
  });

  function mountSidebar() {
    const sidebarEl = document.getElementById("sidebar");
    if (sidebarEl && sidebar && !sidebarInstance) {
      sidebarEl.innerHTML = "";
      lastSidebarEl = sidebarEl;
      sidebarInstance = mount(Sidebar, {
        target: sidebarEl,
        props: {
          directMemberships: sidebar.directMemberships || [],
          otherMemberships: sidebar.otherMemberships || [],
          directPlaceholderUsers: sidebar.directPlaceholderUsers || [],
          canCreateRooms: sidebar.canCreateRooms || false,
          currentUser,
        },
      });
    }
  }

  function unmountSidebar() {
    if (sidebarInstance) {
      try {
        unmount(sidebarInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      sidebarInstance = null;
      lastSidebarEl = null;
    }
  }
</script>

{@render children()}
