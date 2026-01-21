<script>
  import Sidebar from "../../../components/Sidebar.svelte";

  // Props passed by InertiaX Frame
  let {
    router,
    directMemberships = [],
    otherMemberships = [],
    directPlaceholderUsers = [],
    canCreateRooms = false,
    currentUser = null,
  } = $props();
</script>

<!-- This page is rendered inside a Frame, so it shows the Sidebar content directly -->
<Sidebar
  {router}
  {directMemberships}
  {otherMemberships}
  {directPlaceholderUsers}
  {canCreateRooms}
  {currentUser}
/>
