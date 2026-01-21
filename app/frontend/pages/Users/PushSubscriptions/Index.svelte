<script>
  import { onMount } from "svelte";

  import iconArrowLeft from "images/arrow-left.svg";
  import iconBell from "images/notification-bell-everything.svg";
  import iconMinus from "images/minus.svg";

  // Props passed by InertiaX Frame
  let {
    router,
    page,
    pushSubscriptions = [],
    cancelUrl,
    currentUser = null,
  } = $props();

  let deletingIds = $state(new Set());
  let testingIds = $state(new Set());

  onMount(() => {
    // Mount nav
    const navEl = document.getElementById("nav");
    if (navEl) {
      navEl.innerHTML = `
        <div class="flex-item-justify-start">
          <a href="${cancelUrl || "/"}" class="btn btn--plain" data-inertia="true">
            <img src="${iconArrowLeft}" alt="" aria-hidden="true" class="icon" />
            <span>Back</span>
          </a>
        </div>
      `;
    }
  });

  function handleDelete(subscriptionId) {
    const newSet = new Set(deletingIds);
    newSet.add(subscriptionId);
    deletingIds = newSet;

    router.delete(`/users/push_subscriptions/${subscriptionId}`, {
      preserveScroll: true,
      onFinish: () => {
        const updated = new Set(deletingIds);
        updated.delete(subscriptionId);
        deletingIds = updated;
      },
    });
  }

  function handleTestNotification(subscriptionId) {
    const newSet = new Set(testingIds);
    newSet.add(subscriptionId);
    testingIds = newSet;

    router.post(
      `/users/push_subscriptions/${subscriptionId}/test_notifications`,
      {},
      {
        preserveScroll: true,
        onFinish: () => {
          const updated = new Set(testingIds);
          updated.delete(subscriptionId);
          testingIds = updated;
        },
      },
    );
  }

  function handleKeydown(event) {
    if (event.key === "Escape") {
      router.visit(cancelUrl || "/");
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
  <title>Push notification subscriptions</title>
</svelte:head>

<section class="panel panel--wide flex flex-column gap">
  <h1 class="txt-align-center txt-large margin-none">
    Push Notification Subscriptions
  </h1>

  <div class="pad-inline fill-shade border-radius" id="push_subscriptions">
    {#if pushSubscriptions.length === 0}
      <p class="txt-align-center pad translucent">
        No push subscriptions registered.
      </p>
    {:else}
      <menu class="pad flex flex-column gap">
        {#each pushSubscriptions as subscription (subscription.id)}
          <li class="flex flex-column margin-none membership-item">
            <span class="overflow-ellipsis txt-primary txt-undecorated">
              <strong
                >{subscription.browser}
                {subscription.version} on {subscription.platform}</strong
              >
            </span>

            <span class="flex align-start gap txt-small">
              <span class="endpoint">{subscription.endpoint}</span>

              <span class="flex align-center gap actions">
                <button
                  type="button"
                  class="btn btn--reversed"
                  onclick={() => handleTestNotification(subscription.id)}
                  disabled={testingIds.has(subscription.id)}
                  title="Send test notification"
                >
                  <img
                    src={iconBell}
                    aria-hidden="true"
                    alt=""
                    width="20"
                    height="20"
                  />
                  <span class="for-screen-reader">Send test notification</span>
                </button>

                <button
                  type="button"
                  class="btn btn--negative"
                  onclick={() => handleDelete(subscription.id)}
                  disabled={deletingIds.has(subscription.id)}
                  title="Delete subscription"
                >
                  <img
                    src={iconMinus}
                    aria-hidden="true"
                    alt=""
                    width="20"
                    height="20"
                  />
                  <span class="for-screen-reader">Delete subscription</span>
                </button>
              </span>
            </span>
          </li>
        {/each}
      </menu>
    {/if}
  </div>
</section>

<style>
  menu {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .membership-item {
    padding: 0.5rem 0;
    border-bottom: 1px solid var(--color-border, rgba(0, 0, 0, 0.1));
  }

  .membership-item:last-child {
    border-bottom: none;
  }

  .endpoint {
    word-break: break-all;
    flex: 1;
    opacity: 0.7;
  }

  .actions {
    flex-shrink: 0;
  }
</style>
