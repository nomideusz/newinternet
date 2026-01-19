<script>
  import { onMount } from "svelte";

  import iconArrowRight from "images/arrow-right.svg";
  import iconPerson from "images/person.svg";
  import iconLifebuoy from "images/lifebuoy.svg";

  let {
    accountName,
    logoUrl,
    optionsUrl,
    callbackUrl,
    helpContact = null,
    version,
  } = $props();

  // Form state
  let username = $state("");
  let isSubmitting = $state(false);
  let errorMessage = $state("");
  let shake = $state(false);

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
    shake = false;

    const trimmedUsername = username.trim().toLowerCase();
    if (!trimmedUsername) {
      showError("Please enter your username");
      return;
    }

    isSubmitting = true;

    try {
      // Get assertion options from server
      const optionsResponse = await fetch(optionsUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
        },
        body: JSON.stringify({ username: trimmedUsername }),
      });

      if (!optionsResponse.ok) {
        const data = await optionsResponse.json();
        throw new Error(data.error || "User not found");
      }

      const options = await optionsResponse.json();

      // Convert challenge and allowCredentials for WebAuthn API
      options.challenge = base64urlToBuffer(options.challenge);
      if (options.allowCredentials) {
        options.allowCredentials = options.allowCredentials.map((cred) => ({
          ...cred,
          id: base64urlToBuffer(cred.id),
        }));
      }

      // Get credential from authenticator (biometric/PIN prompt)
      const credential = await navigator.credentials.get({ publicKey: options });

      // Prepare credential for server
      const credentialData = {
        id: credential.id,
        rawId: bufferToBase64url(credential.rawId),
        type: credential.type,
        response: {
          authenticatorData: bufferToBase64url(credential.response.authenticatorData),
          clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
          signature: bufferToBase64url(credential.response.signature),
          userHandle: credential.response.userHandle
            ? bufferToBase64url(credential.response.userHandle)
            : null,
        },
      };

      // Verify with server
      const verifyResponse = await fetch(callbackUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken(),
        },
        body: JSON.stringify({ credential: credentialData }),
      });

      if (verifyResponse.ok) {
        const data = await verifyResponse.json();
        window.location.href = data.redirect_url || "/";
      } else {
        const data = await verifyResponse.json();
        throw new Error(data.error || "Authentication failed");
      }
    } catch (error) {
      console.error("WebAuthn error:", error);
      showError(error.message || "Authentication failed");
    } finally {
      isSubmitting = false;
    }
  }

  function showError(message) {
    errorMessage = message;
    shake = true;
    // Remove shake class after animation
    setTimeout(() => {
      shake = false;
    }, 500);
  }

  // Focus username input on mount
  let usernameInput;
  onMount(() => {
    usernameInput?.focus();
  });
</script>

<svelte:head>
  <title>Sign in</title>
</svelte:head>

<section class="login-section txt-align-center">
  <div class="panel {shake ? 'shake' : ''}">
    <figure class="account-logo avatar center margin-block-end txt-xx-large">
      <img src={logoUrl} alt="Account logo" />
    </figure>

    <form onsubmit={handleSubmit} class="flex flex-column gap">
      <fieldset class="flex flex-column gap center-block upad">
        <legend class="txt-large txt-align-center">
          <strong>{accountName}</strong>
        </legend>

        {#if errorMessage}
          <p class="txt-danger txt-align-center">{errorMessage}</p>
        {/if}

        <div class="flex align-center gap">
          <label class="flex align-center gap input input--actor txt-large">
            <input
              type="text"
              name="username"
              required
              class="input"
              autocomplete="username webauthn"
              placeholder="Enter your username"
              bind:value={username}
              bind:this={usernameInput}
              disabled={isSubmitting}
            />
            <img src={iconPerson} aria-hidden="true" alt="" width="24" height="24" class="colorize--black" />
          </label>
        </div>

        <button
          class="btn btn--reversed center txt-large"
          type="submit"
          disabled={isSubmitting}
        >
          <img src={iconArrowRight} aria-hidden="true" alt="" />
          <span>{isSubmitting ? "Signing in..." : "Sign in with Passkey"}</span>
        </button>
      </fieldset>
    </form>
  </div>

  {#if helpContact}
    <div class="txt-align-center margin-block-double full-width">
      <a href="mailto:&quot;{helpContact.name}&quot; <{helpContact.email}>" class="btn center" title="Email {helpContact.name}">
        <img src={iconLifebuoy} aria-hidden="true" alt="" />
        <span>{helpContact.email}</span>
      </a>

      <div class="txt-align-center center margin-block txt-subtle">
        New Internet v{version}
      </div>
    </div>
  {/if}
</section>

<style>
  .login-section {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    min-height: 100dvh;
    padding: 2rem;
  }

  .panel {
    background: var(--color-surface, #fff);
    border-radius: 1rem;
    padding: 2rem;
    max-width: 24rem;
    width: 100%;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.1);
  }

  .panel.shake {
    animation: shake 0.5s ease-in-out;
  }

  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
    20%, 40%, 60%, 80% { transform: translateX(5px); }
  }

  .account-logo {
    width: 6rem;
    height: 6rem;
    border-radius: 50%;
    overflow: hidden;
  }

  .account-logo img {
    width: 100%;
    height: 100%;
    object-fit: cover;
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

  .btn--reversed {
    width: 100%;
    justify-content: center;
    gap: 0.5rem;
  }

  .txt-danger {
    color: var(--color-danger, #dc3545);
  }

  .margin-block-double {
    margin-block: 2rem;
  }

  .txt-subtle {
    opacity: 0.6;
  }
</style>
