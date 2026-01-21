import { createInertiaApp } from "inertiax-svelte";
import { mount } from "svelte";
import Layout from "../layouts/Layout.svelte";

// Import shared styles for Svelte components
import "../styles/shared.css";

// Pages that should use the main Layout with sidebar
const pagesWithLayout = [
  "Rooms/Show",
  "Rooms/Directs/New",
  "Rooms/Directs/Edit",
  "Rooms/Opens/New",
  "Rooms/Opens/Edit",
  "Users/Profiles/Show",
  "Accounts/Edit",
  "Searches/Index",
  "Welcome/Show",
  "Test/Reactivity",
];

console.log("[Inertia X] Initializing Inertia app...");

createInertiaApp({
  // Disable the progress bar (blue loading indicator at top)
  progress: false,
  
  resolve: (name) => {
    console.log("[Inertia X] Resolving page:", name);
    const pages = import.meta.glob("../pages/**/*.svelte", { eager: true });
    const page = pages[`../pages/${name}.svelte`];
    if (!page) {
      console.error(`[Inertia X] Page not found: ${name}`);
      return page;
    }
    
    // Assign layout for pages that need the sidebar
    if (pagesWithLayout.includes(name)) {
      return {
        default: page.default,
        layout: Layout,
      };
    }
    
    return page;
  },
  setup({ el, App, props }) {
    console.log("[Inertia X] Setting up app, element:", el);
    console.log("[Inertia X] Initial page:", props.initialPage?.component);

    // Clear the element
    el.innerHTML = "";

    // Mount the Inertia app
    return mount(App, {
      target: el,
      props,
    });
  },
});
