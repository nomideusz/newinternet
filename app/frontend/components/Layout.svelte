<script>
  import { onMount, onDestroy, mount, unmount } from "svelte";
  import Sidebar from "./Sidebar.svelte";

  let {
    sidebar = null,
    currentUser = null,
    children,
  } = $props();

  // Track mounted sidebar instance - NOT reactive state
  let sidebarInstance = null;

  onMount(() => {
    // Mount sidebar into the #sidebar element if sidebar data is provided
    const sidebarEl = document.getElementById("sidebar");
    if (sidebarEl && sidebar) {
      sidebarEl.innerHTML = "";
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
  });

  onDestroy(() => {
    // Clean up mounted sidebar
    if (sidebarInstance) {
      try {
        unmount(sidebarInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      sidebarInstance = null;
    }
  });
</script>

{@render children()}
