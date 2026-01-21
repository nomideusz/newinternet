<script>
  import { getContext } from "svelte";

  let { user } = $props();

  // Get the top-level router for navigation (this component is in sidebar frame, needs to navigate _top)
  const { router } = getContext("inertia:_top");

  let isSubmitting = $state(false);

  function handleClick() {
    if (isSubmitting) return;
    isSubmitting = true;

    router.post(
      "/rooms/directs",
      { user_ids: [user.id] },
      {
        onFinish: () => {
          isSubmitting = false;
        },
      },
    );
  }
</script>

<button
  type="button"
  class="direct borderless fill-transparent unpad"
  onclick={handleClick}
  disabled={isSubmitting}
>
  <span class="avatar">
    <img src={user.avatarUrl} aria-hidden="true" alt="" />
  </span>

  <span
    class="direct__author flex align-center gap max-width min-width border-radius txt-small"
  >
    <span class="txt-nowrap overflow-ellipsis">
      <span class="for-screen-reader">Start a ping with</span>
      {user.name.split(" ")[0]}
    </span>
  </span>
</button>
