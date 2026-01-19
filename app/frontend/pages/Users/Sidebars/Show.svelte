<script>
  let {
    page,
    directMemberships = [],
    otherMemberships = [],
    directPlaceholderUsers = [],
    canCreateRooms = false,
    currentUser,
  } = $props();

  // Sidebar is now mounted by the global sidebarManager in inertia.js
  // This page just shows the main content area
</script>

<div class="message-area">
  <div class="message-area--empty min-width center">
    <figure class="center pad">
      <span class="translucent txt-large">Select a conversation</span>
    </figure>
  </div>
</div>
