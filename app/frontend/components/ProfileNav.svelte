<script>
  import iconArrowLeft from "images/arrow-left.svg";
  import iconLogout from "images/logout.svg";

  // Props - router passed from parent
  let { router = null } = $props();

  function handleBack() {
    if (window.history.length > 1) {
      window.history.back();
    } else if (router) {
      router.visit("/");
    } else {
      window.location.href = "/";
    }
  }

  function handleLogout() {
    // Get push subscription endpoint if available
    if ("serviceWorker" in navigator && "PushManager" in window) {
      navigator.serviceWorker.ready
        .then((registration) => registration.pushManager.getSubscription())
        .then((subscription) => {
          submitLogout(subscription?.endpoint);
        })
        .catch(() => submitLogout(null));
    } else {
      submitLogout(null);
    }
  }

  function submitLogout(endpoint) {
    const form = document.createElement("form");
    form.method = "POST";
    form.action = "/session";

    const methodInput = document.createElement("input");
    methodInput.type = "hidden";
    methodInput.name = "_method";
    methodInput.value = "delete";
    form.appendChild(methodInput);

    const csrfToken = document.querySelector(
      'meta[name="csrf-token"]',
    )?.content;
    if (csrfToken) {
      const csrfInput = document.createElement("input");
      csrfInput.type = "hidden";
      csrfInput.name = "authenticity_token";
      csrfInput.value = csrfToken;
      form.appendChild(csrfInput);
    }

    if (endpoint) {
      const endpointInput = document.createElement("input");
      endpointInput.type = "hidden";
      endpointInput.name = "push_subscription_endpoint";
      endpointInput.value = endpoint;
      form.appendChild(endpointInput);
    }

    document.body.appendChild(form);
    form.submit();
  }
</script>

<nav class="nav flex align-center gap">
  <div class="flex-item-justify-start">
    <button type="button" class="btn" onclick={handleBack}>
      <img
        src={iconArrowLeft}
        aria-hidden="true"
        width="20"
        height="20"
        alt=""
        class="adaptive-icon"
      />
      <span class="for-screen-reader">Go back</span>
    </button>
  </div>

  <div class="flex-item-grow"></div>

  <div class="flex-item-justify-end">
    <button type="button" class="btn" onclick={handleLogout}>
      <img
        src={iconLogout}
        aria-hidden="true"
        width="20"
        height="20"
        alt=""
        class="adaptive-icon"
      />
      <span class="for-screen-reader">Log out</span>
    </button>
  </div>
</nav>

<style>
  :global(:root[data-theme="dark"]) .adaptive-icon {
    filter: invert(1) !important;
  }
  @media (prefers-color-scheme: dark) {
    .adaptive-icon {
      filter: invert(1) !important;
    }
  }
</style>
