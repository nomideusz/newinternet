<script>
  import { onMount } from "svelte";

  import iconArrowRight from "images/arrow-right.svg";
  import iconLanyard from "images/lanyard.svg";

  let {
    optionsUrl,
    callbackUrl,
  } = $props();

  // Form state
  let username = $state("");
  let isSubmitting = $state(false);
  let errorMessage = $state("");

  // WebAuthn utilities
  function bufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer);
    let str = "";
    for (const byte of bytes) {
      str += String.fromCharCode(byte);
    }
    return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }

  function base64urlToBuffer(base64url) {
    const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/");
    const padding = "=".repeat((4 - (base64.length % 4)) % 4);
    const binary = atob(base64 + padding);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }

  function getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content;
  }

  async function handleSubmit(event) {
    event.preventDefault();
    errorMessage = "";

    const trimmedUsername = username.trim().toLowerCase();
    if (!trimmedUsername) {
      errorMessage = "Please enter a username";
      return;
    }

    // Validate username format
    if (!/^[a-z0-9_]+$/.test(trimmedUsername)) {
      errorMessage = "Username can only contain lowercase letters, numbers, and underscores";
      return;
    }

    isSubmitting = true;

    try {
      // Get creation options from server
      const optionsResponse = await fetch(optionsUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
        },
        body: JSON.stringify({ username: trimmedUsername, name: trimmedUsername }),
      });

      if (!optionsResponse.ok) {
        const data = await optionsResponse.json();
        throw new Error(data.error || "Setup failed");
      }

      const options = await optionsResponse.json();

      // Convert for WebAuthn API
      options.challenge = base64urlToBuffer(options.challenge);
      options.user.id = base64urlToBuffer(options.user.id);
      if (options.excludeCredentials) {
        options.excludeCredentials = options.excludeCredentials.map((cred) => ({
          ...cred,
          id: base64urlToBuffer(cred.id),
        }));
      }

      // Create credential on authenticator (biometric/PIN prompt)
      const credential = await navigator.credentials.create({
        publicKey: options,
      });

      // Prepare credential for server
      const credentialData = {
        id: credential.id,
        rawId: bufferToBase64url(credential.rawId),
        type: credential.type,
        response: {
          attestationObject: bufferToBase64url(credential.response.attestationObject),
          clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
        },
      };

      // Complete registration with server
      const callbackResponse = await fetch(callbackUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
        },
        body: JSON.stringify({ credential: credentialData }),
      });

      if (callbackResponse.ok) {
        const data = await callbackResponse.json();
        window.location.href = data.redirect_url || "/";
      } else {
        const data = await callbackResponse.json();
        throw new Error(data.error || "Setup failed");
      }
    } catch (error) {
      console.error("WebAuthn error:", error);
      errorMessage = error.message || "Setup failed";
    } finally {
      isSubmitting = false;
    }
  }

  // Focus username input on mount
  let usernameInput;
  onMount(() => {
    usernameInput?.focus();
  });
</script>

<svelte:head>
  <title>Set up New Internet</title>
</svelte:head>

<div class="signup center max-width">
  <section class="nametag u-relative">
    <div class="flex justify-center align-center pad-block lanyard-bg">
      <img src={iconLanyard} class="nametag__lanyard" aria-hidden="true" alt="" />
    </div>

    <form onsubmit={handleSubmit} class="nametag__inner flex flex-column gap">
      <fieldset class="flex flex-column center-block">
        <legend class="txt-large txt-align-center">
          <strong>Set up New Internet</strong>
        </legend>

        {#if errorMessage}
          <p class="txt-danger txt-align-center">{errorMessage}</p>
        {/if}

        <div class="flex align-center gap margin-block-start">
          <label class="flex align-center gap flex-item-grow txt-large input input--actor">
            <input
              type="text"
              name="username"
              class="input"
              autocomplete="username"
              placeholder="Choose a username"
              required
              pattern="[a-z0-9_]+"
              title="Lowercase letters, numbers, and underscores only"
              bind:value={username}
              bind:this={usernameInput}
              disabled={isSubmitting}
            />
            <span class="txt-muted">@</span>
          </label>
        </div>

        <p class="txt-small txt-muted txt-align-center margin-block">
          Your device will prompt you to create a passkey.<br />
          This replaces passwords — just use Face ID, Touch ID, or your device PIN.
        </p>

        <button
          class="btn btn--reversed center txt-large"
          type="submit"
          disabled={isSubmitting}
        >
          <img src={iconArrowRight} aria-hidden="true" alt="" />
          <span>{isSubmitting ? "Setting up..." : "Create Account"}</span>
        </button>
      </fieldset>
    </form>
  </section>
</div>

<style>
  /* First-run setup - minimal overrides, using app's signup.css */
  .signup.center {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    min-height: 100dvh;
    padding: var(--block-space);
  }

  .signup.max-width {
    max-width: 100%;
    width: 100%;
  }

  .lanyard-bg {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }

  fieldset {
    border: none;
    padding: 0;
    margin: 0;
  }

  legend {
    width: 100%;
    margin-bottom: 1rem;
  }

  .input--actor {
    width: 100%;
  }

  .input--actor input {
    flex: 1;
    border: none;
    background: transparent;
    outline: none;
  }
</style>
