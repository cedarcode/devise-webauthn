import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hiddenPasskeyPublicKeyInput"]

  async create({ params: { options } }) {
    try {
      const passkeyOptions = PublicKeyCredential.parseCreationOptionsFromJSON(options);
      const passkeyPublicKey = await navigator.credentials.create({ publicKey: passkeyOptions });

      this.hiddenPasskeyPublicKeyInputTarget.value = JSON.stringify(passkeyPublicKey);

      this.element.submit();
    } catch (error) {
      alert(error.message || error);
    }
  }

  async get({ params: { options } }) {
    try {
      const passkeyOptions = PublicKeyCredential.parseRequestOptionsFromJSON(options);
      const passkeyPublicKey = await navigator.credentials.get({ publicKey: passkeyOptions });

      this.hiddenPasskeyPublicKeyInputTarget.value = JSON.stringify(passkeyPublicKey);

      this.element.submit();
    } catch (error) {
      alert(error.message || error);
    }
  }
}
