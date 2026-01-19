<script>
  import { onMount, onDestroy, mount, unmount } from "svelte";
  import Sidebar from "../components/Sidebar.svelte";

  let {
    children,
    sidebar = null,
    currentUser = null,
  } = $props();

  // Track mounted sidebar instance - persists across page navigations
  let sidebarInstance = null;
  let sidebarMounted = false;

  // Store the latest sidebar props to update on navigation
  let latestSidebarProps = $state(null);

  $effect(() => {
    // Update props reference when they change
    if (sidebar) {
      latestSidebarProps = sidebar;
    }
  });

  onMount(() => {
    mountSidebar();
  });

  onDestroy(() => {
    unmountSidebar();
  });

  function mountSidebar() {
    const sidebarEl = document.getElementById("sidebar");
    if (sidebarEl && sidebar && !sidebarMounted) {
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
      sidebarMounted = true;
    }
  }

  function unmountSidebar() {
    if (sidebarInstance && sidebarMounted) {
      try {
        unmount(sidebarInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      sidebarInstance = null;
      sidebarMounted = false;
    }
  }
</script>

{@render children()}
