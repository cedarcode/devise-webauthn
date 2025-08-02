import { Controller } from "@hotwired/stimulus"
import * as WebAuthnJSON from "@github/webauthn-json/browser-ponyfill"

export default class extends Controller {
  static targets = ["hiddenPasskeyPublicKeyInput"]
  static values = { errorMessages: Object }

  async create({ params: { publicKey } }) {
    try{
      const passkeyOptions = WebAuthnJSON.parseCreationOptionsFromJSON({ publicKey });
      const passkeyPublicKey = await WebAuthnJSON.create(passkeyOptions);

      this.hiddenPasskeyPublicKeyInputTarget.value = JSON.stringify(passkeyPublicKey);

      this.element.submit();

    } catch (error) {
      this.handleError(error);
    }
  }

  async get({ params: {publicKey} }) {
    try {
      const passkeyOptions = WebAuthnJSON.parseRequestOptionsFromJSON({ publicKey });
      const passkeyPublicKey = await WebAuthnJSON.get(passkeyOptions);

      this.hiddenPasskeyPublicKeyInputTarget.value = JSON.stringify(passkeyPublicKey);

      this.element.submit();

    } catch (error) {
      this.handleError(error);
    }
  }

  handleError(error) {
    const errorMessages = this.errorMessagesValue || {};

    let message;
    switch (error.name) {
      case "NotAllowedError":
        message = errorMessages.not_allowed;
        break;
      case "InvalidStateError":
        message = errorMessages.invalid_state;
        break;
      case "SecurityError":
        message = errorMessages.security_error;
        break;
      case "NotSupportedError":
        message = errorMessages.not_supported;
        break;
      case "AbortError":
        message = errorMessages.aborted;
        break;
      default:
        message = `Error: ${error.message || error}`;
    }

    alert(message);
  }
}
