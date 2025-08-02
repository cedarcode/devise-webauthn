import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hiddenPasskeyPublicKeyInput"]
  static values = { errorMessages: Object }

  async create({ params: { options } }) {
    try {
      const passkeyOptions = PublicKeyCredential.parseCreationOptionsFromJSON(options);
      const passkeyPublicKey = await navigator.credentials.create({ publicKey: passkeyOptions });

      this.hiddenPasskeyPublicKeyInputTarget.value = JSON.stringify(passkeyPublicKey);

      this.element.submit();

    } catch (error) {
      this.handleError(error);
    }
  }

  async get({ params: { options } }) {
    try {
      const passkeyOptions = PublicKeyCredential.parseRequestOptionsFromJSON(options);
      const passkeyPublicKey = await navigator.credentials.get({ publicKey: passkeyOptions });

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
