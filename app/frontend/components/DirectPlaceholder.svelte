<script>
  import { router } from "@inertiajs/svelte"

  let { user } = $props()

  let isSubmitting = $state(false)

  function handleClick() {
    if (isSubmitting) return
    isSubmitting = true

    router.post(
      "/rooms/directs",
      { user_ids: [user.id] },
      {
        onFinish: () => {
          isSubmitting = false
        }
      }
    )
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

  <span class="direct__author flex align-center gap max-width min-width border-radius txt-small">
    <span class="txt-nowrap overflow-ellipsis">
      <span class="for-screen-reader">Start a ping with</span>
      {user.name.split(' ')[0]}
    </span>
  </span>
</button>
