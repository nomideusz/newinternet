import { Controller } from "@hotwired/stimulus";

// Utility functions for base64url encoding/decoding
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

// WebAuthn controller for passkey registration and authentication
export default class extends Controller {
  static targets = ["username", "name", "form", "error", "submit"];
  static values = {
    mode: String, // "login" | "register" | "firstrun"
    optionsUrl: String,
    callbackUrl: String,
  };

  async authenticate(event) {
    event.preventDefault();
    this.clearError();
    this.disableSubmit();

    try {
      if (this.modeValue === "login") {
        await this.login();
      } else {
        await this.register();
      }
    } catch (error) {
      console.error("WebAuthn error:", error);
      this.showError(error.message || "Authentication failed");
      this.enableSubmit();
    }
  }

  async login() {
    const username = this.usernameTarget.value.trim().toLowerCase();

    if (!username) {
      throw new Error("Please enter your username");
    }

    // Get assertion options from server
    const optionsResponse = await fetch(this.optionsUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({ username }),
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
        authenticatorData: bufferToBase64url(
          credential.response.authenticatorData,
        ),
        clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
        signature: bufferToBase64url(credential.response.signature),
        userHandle: credential.response.userHandle
          ? bufferToBase64url(credential.response.userHandle)
          : null,
      },
    };

    // Verify with server
    const verifyResponse = await fetch(this.callbackUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
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
  }

  async register() {
    const username = this.usernameTarget.value.trim().toLowerCase();
    const name = this.hasNameTarget ? this.nameTarget.value.trim() : username;

    if (!username) {
      throw new Error("Please enter a username");
    }

    if (!name && this.hasNameTarget) {
      throw new Error("Please enter your name");
    }

    // Get creation options from server
    const optionsResponse = await fetch(this.optionsUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({ username, name }),
    });

    if (!optionsResponse.ok) {
      const data = await optionsResponse.json();
      throw new Error(data.error || "Registration failed");
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
        attestationObject: bufferToBase64url(
          credential.response.attestationObject,
        ),
        clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
      },
    };

    // Complete registration with server
    const callbackResponse = await fetch(this.callbackUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({ credential: credentialData }),
    });

    if (callbackResponse.ok) {
      const data = await callbackResponse.json();
      window.location.href = data.redirect_url || "/";
    } else {
      const data = await callbackResponse.json();
      throw new Error(data.error || "Registration failed");
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content;
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message;
      this.errorTarget.hidden = false;
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = "";
      this.errorTarget.hidden = true;
    }
  }

  disableSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true;
      this.submitTarget.textContent = "Please wait...";
    }
  }

  enableSubmit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false;
    }
  }
}
