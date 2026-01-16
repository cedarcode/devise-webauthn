function isWebAuthnSupported() {
  return !!(
    navigator.credentials &&
    navigator.credentials.create &&
    navigator.credentials.get &&
    window.PublicKeyCredential
  );
}

export class WebauthnCreateElement extends HTMLElement {
  connectedCallback() {
    this.style.display = 'contents';

    if (!isWebAuthnSupported()) {
      this.handleWebauthnUnsupported();
      return;
    }

    this.closest('form').addEventListener('submit', async (event) => {
      event.preventDefault();

      try {
        const options = JSON.parse(this.getAttribute('data-options-json'));
        const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(options);
        const credential = await navigator.credentials.create({ publicKey });

        this.querySelector('[data-webauthn-target="response"]').value = await this.stringifyRegistrationCredentialWithGracefullyHandlingAuthenticatorIssues(credential);

        this.closest('form').submit();
      } catch (error) {
        this.handleError(error);
      }
    });
  }

  handleError(error) {
    const event = new CustomEvent('webauthn:prompt:error', {
      detail: { error, action: 'create' },
      bubbles: true,
      cancelable: true
    });

    // If no listener prevents default, show alert
    if (this.dispatchEvent(event)) {
      alert(error.message || error);
    }
  }

  handleWebauthnUnsupported() {
    this.dispatchEvent(new CustomEvent('webauthn:unsupported', {
      detail: { action: 'create' },
      bubbles: true
    }));
  }

  // Stringifies registration credentials gracefully handling malformed ones (e.g., due to issues with
  // certain authenticators like 1Password).
  // It first tries to stringify them normally, and if the credential cannot be stringified (because its
  // malformed), it attempts a workaround to convert the malformed credential into a valid format. This
  // workaround was introduced for 1Password and might fail for other authenticators.
  //
  // Authenticators that return a proper credential should not affected by this workaround!
  async stringifyRegistrationCredentialWithGracefullyHandlingAuthenticatorIssues(credential) {
    try {
      return JSON.stringify(credential);
    } catch (e) {
      console.warn("Authenticator returned a malformed credential, attempting to fix it. Error was:", e);
    }

    const response = credential.response;
    const publicKey = response.getPublicKey ? await response.getPublicKey() : null;

    return JSON.stringify({
      type: credential.type,
      id: credential.id,
      rawId: credential.id,
      authenticatorAttachment: credential.authenticatorAttachment,
      clientExtensionResults: await credential.getClientExtensionResults(),
      response: {
        attestationObject: toBase64Url(response.attestationObject),
        authenticatorData: toBase64Url(response.authenticatorData),
        clientDataJSON: toBase64Url(response.clientDataJSON),
        publicKey: toBase64Url(publicKey),
        publicKeyAlgorithm: response.getPublicKeyAlgorithm(),
        transports: response.getTransports(),
      },
    });
  }
}

export class WebauthnGetElement extends HTMLElement {
  connectedCallback() {
    this.style.display = 'contents';

    if (!isWebAuthnSupported()) {
      this.handleWebauthnUnsupported();
      return;
    }

    this.closest('form').addEventListener('submit', async (event) => {
      event.preventDefault();

      try {
        const options = JSON.parse(this.getAttribute('data-options-json'));
        const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(options);
        const credential = await navigator.credentials.get({ publicKey });

        this.querySelector('[data-webauthn-target="response"]').value = await this.stringifyAuthenticationCredentialWithGracefullyHandlingAuthenticatorIssues(credential);

        this.closest('form').submit();
      } catch (error) {
        this.handleError(error);
      }
    });
  }

  handleError(error) {
    const event = new CustomEvent('webauthn:prompt:error', {
      detail: { error, action: 'get' },
      bubbles: true,
      cancelable: true
    });

    // If no listener prevents default, show alert
    if (this.dispatchEvent(event)) {
      alert(error.message || error);
    }
  }

  handleWebauthnUnsupported() {
    this.dispatchEvent(new CustomEvent('webauthn:unsupported', {
      detail: { action: 'get' },
      bubbles: true
    }));
  }

  // Stringifies authentication credentials gracefully handling malformed ones (e.g., due to issues with
  // certain authenticators like 1Password).
  // It first tries to stringify them normally, and if the credential cannot be stringified (because its
  // malformed), it attempts a workaround to convert the malformed credential into a valid format. This
  // workaround was introduced for 1Password and might fail for other authenticators.
  //
  // Authenticators that return a proper credential should not affected by this workaround!
  async stringifyAuthenticationCredentialWithGracefullyHandlingAuthenticatorIssues(credential) {
    try {
      return JSON.stringify(credential);
    } catch (e) {
      console.warn("Authenticator returned a malformed credential, attempting to fix it. Error was:", e);
    }

    const response = credential.response;

    return JSON.stringify({
      type: credential.type,
      id: credential.id,
      rawId: credential.id,
      authenticatorAttachment: credential.authenticatorAttachment,
      clientExtensionResults: await credential.getClientExtensionResults(),
      response: {
        authenticatorData: toBase64Url(response.authenticatorData),
        clientDataJSON: toBase64Url(response.clientDataJSON),
        signature: toBase64Url(response.signature),
        userHandle: response.userHandle ? toBase64Url(response.userHandle) : null,
      },
    });
  }
}

function toBase64Url(buffer) {
  if (!buffer) return null;

  const binary = String.fromCharCode(...new Uint8Array(buffer));
  const base64 = btoa(binary);

  return base64.replaceAll("+", "-").replaceAll("/", "_");
}

customElements.define('webauthn-create', WebauthnCreateElement);
customElements.define('webauthn-get', WebauthnGetElement);
