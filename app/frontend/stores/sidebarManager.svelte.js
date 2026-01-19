import { mount, unmount } from "svelte";
import Sidebar from "../components/Sidebar.svelte";

// Global state - track sidebar mounting
let sidebarInstance = null;
let mountedUserId = null;

export const sidebarManager = {
  /**
   * Mount the sidebar if not already mounted or if user changed
   * @param {Object} props - Sidebar props
   */
  mount(props) {
    const sidebarEl = document.getElementById("sidebar");

    if (!sidebarEl) {
      return;
    }

    const newUserId = props.currentUser?.id;

    // Skip if already mounted for the same user
    if (sidebarInstance && mountedUserId === newUserId) {
      return;
    }

    // If sidebar element already has content (from previous mount), skip
    // This handles the case where the sidebar persists across navigation
    if (sidebarEl.children.length > 0 && sidebarInstance) {
      return;
    }

    // Unmount existing instance if user changed
    if (sidebarInstance && mountedUserId !== newUserId) {
      this.unmount();
    }

    // Clear and mount fresh
    sidebarEl.innerHTML = "";

    sidebarInstance = mount(Sidebar, {
      target: sidebarEl,
      props: {
        directMemberships: props.directMemberships || [],
        otherMemberships: props.otherMemberships || [],
        directPlaceholderUsers: props.directPlaceholderUsers || [],
        canCreateRooms: props.canCreateRooms || false,
        currentUser: props.currentUser,
      },
    });

    mountedUserId = newUserId;
  },

  /**
   * Unmount the sidebar
   */
  unmount() {
    if (sidebarInstance) {
      try {
        unmount(sidebarInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      sidebarInstance = null;
      mountedUserId = null;
    }
  },

  /**
   * Check if sidebar is mounted
   */
  isMounted() {
    return sidebarInstance !== null;
  },

  /**
   * Check if sidebar needs mounting
   * @param {string|number} userId - Current user ID
   */
  needsMount(userId) {
    const sidebarEl = document.getElementById("sidebar");

    // Needs mount if: no instance, different user, or empty element
    if (!sidebarInstance) return true;
    if (mountedUserId !== userId) return true;
    if (sidebarEl && sidebarEl.children.length === 0) return true;

    return false;
  },
};
