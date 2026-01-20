import { mount, unmount } from "svelte";
import NavBar from "../components/NavBar.svelte";

// Global state - track nav avatar mounting
let navInstance = null;
let mountedUserId = null;

export const navManager = {
  /**
   * Mount the nav avatar if not already mounted or if user changed
   * @param {Object} props - Nav props including currentUser
   */
  mount(props) {
    const navAvatarEl = document.getElementById("nav-avatar");

    if (!navAvatarEl) {
      return;
    }

    const newUserId = props.currentUser?.id;

    // Skip if already mounted for the same user
    if (navInstance && mountedUserId === newUserId) {
      return;
    }

    // Unmount existing instance if user changed
    if (navInstance && mountedUserId !== newUserId) {
      this.unmount();
    }

    // Clear and mount fresh
    navAvatarEl.innerHTML = "";

    navInstance = mount(NavBar, {
      target: navAvatarEl,
      props: {
        currentUser: props.currentUser,
      },
    });

    mountedUserId = newUserId;
  },

  /**
   * Unmount the nav bar
   */
  unmount() {
    if (navInstance) {
      try {
        unmount(navInstance);
      } catch (e) {
        // Component may already be unmounted
      }
      navInstance = null;
      mountedUserId = null;
    }
  },

  /**
   * Check if nav is mounted
   */
  isMounted() {
    return navInstance !== null;
  },

  /**
   * Check if nav needs mounting
   * @param {string|number} userId - Current user ID
   */
  needsMount(userId) {
    const navEl = document.getElementById("nav");

    // Needs mount if: no instance, different user, or empty element
    if (!navInstance) return true;
    if (mountedUserId !== userId) return true;
    if (navEl && navEl.children.length === 0) return true;

    return false;
  },
};
