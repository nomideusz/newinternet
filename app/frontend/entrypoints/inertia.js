import { createInertiaApp, router } from "@inertiajs/svelte";
import { mount } from "svelte";
import { sidebarManager } from "../stores/sidebarManager.svelte.js";

// Import shared styles for Svelte components
import "../styles/shared.css";

console.log("[Inertia] Initializing Inertia app...");

// Disable the default progress bar by providing empty handlers
// The blue bar won't show anymore during navigation

// Pages that should have the sidebar
const pagesWithSidebar = [
  "Rooms/Show",
  "Rooms/Directs/New",
  "Rooms/Directs/Edit",
  "Rooms/Opens/New",
  "Rooms/Opens/Edit",
  "Users/Sidebars/Show",
  "Users/Profiles/Show",
  "Accounts/Edit",
  "Searches/Index",
  "Welcome/Show",
  "Test/Reactivity",
];

/**
 * Extract sidebar props from page props
 */
function getSidebarProps(pageProps) {
  // Some pages have sidebar nested, others have it flat
  if (pageProps.sidebar) {
    return {
      directMemberships: pageProps.sidebar.directMemberships || [],
      otherMemberships: pageProps.sidebar.otherMemberships || [],
      directPlaceholderUsers: pageProps.sidebar.directPlaceholderUsers || [],
      canCreateRooms: pageProps.sidebar.canCreateRooms || false,
      currentUser: pageProps.currentUser,
    };
  }

  // Flat structure (Users/Sidebars/Show)
  return {
    directMemberships: pageProps.directMemberships || [],
    otherMemberships: pageProps.otherMemberships || [],
    directPlaceholderUsers: pageProps.directPlaceholderUsers || [],
    canCreateRooms: pageProps.canCreateRooms || false,
    currentUser: pageProps.currentUser,
  };
}

/**
 * Mount sidebar if needed for the current page
 */
function mountSidebarIfNeeded(pageName, pageProps) {
  if (!pagesWithSidebar.includes(pageName)) {
    return;
  }

  const props = getSidebarProps(pageProps);
  const userId = props.currentUser?.id;

  // Determine if this is a room page (where the chat should be visible on mobile)
  const isRoomPage = pageName === "Rooms/Show";

  // Only mount if needed (not already mounted for this user)
  if (sidebarManager.needsMount(userId)) {
    sidebarManager.mount(props, { isRoomPage });
  } else {
    // Even if already mounted, we need to update the room-open state on mobile
    sidebarManager.mount(props, { isRoomPage });
  }
}

createInertiaApp({
  // Disable the progress bar (blue loading indicator at top)
  // Set to false to completely disable, or customize: { delay: 250, color: '#29d', ... }
  progress: false,
  
  resolve: (name) => {
    console.log("[Inertia] Resolving page:", name);
    const pages = import.meta.glob("../pages/**/*.svelte", { eager: true });
    const page = pages[`../pages/${name}.svelte`];
    if (!page) {
      console.error(`[Inertia] Page not found: ${name}`);
    }
    return page;
  },
  setup({ el, App, props }) {
    console.log("[Inertia] Setting up app, element:", el);
    console.log("[Inertia] Initial page:", props.initialPage?.component);
    
    const pageName = props.initialPage?.component;
    const pageProps = props.initialPage?.props || {};

    // Mount sidebar using the global manager
    mountSidebarIfNeeded(pageName, pageProps);

    // Clear the element
    el.innerHTML = "";

    // Mount the Inertia app
    return mount(App, {
      target: el,
      props,
    });
  },
});

// Listen for Inertia navigation events to ensure sidebar stays mounted
if (typeof window !== "undefined") {
  document.addEventListener("inertia:navigate", (event) => {
    console.log("[Inertia] Navigation event:", event.detail?.page?.component);
    const pageName = event.detail?.page?.component;
    const pageProps = event.detail?.page?.props || {};

    // Re-mount sidebar if needed after navigation
    mountSidebarIfNeeded(pageName, pageProps);
  });

  // Debug: Listen for all navigation attempts
  document.addEventListener("inertia:before", (event) => {
    console.log("[Inertia] Before navigation to:", event.detail?.visit?.url);
  });

  document.addEventListener("inertia:start", (event) => {
    console.log("[Inertia] Started navigation");
  });

  document.addEventListener("inertia:finish", (event) => {
    console.log("[Inertia] Finished navigation");
  });
}
