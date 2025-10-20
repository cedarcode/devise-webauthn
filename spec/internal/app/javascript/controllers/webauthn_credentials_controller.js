import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["credentialHiddenInput"]

  async create({ params: { options } }) {
    try {
      const credentialOptions = PublicKeyCredential.parseCreationOptionsFromJSON(options);
      const credential = await navigator.credentials.create({ publicKey: credentialOptions });

      this.credentialHiddenInputTarget.value = JSON.stringify(credential);

      this.element.submit();
    } catch (error) {
      alert(error.message || error);
    }
  }

  async get({ params: { options } }) {
    try {
      const credentialOptions = PublicKeyCredential.parseRequestOptionsFromJSON(options);
      const credential = await navigator.credentials.get({ publicKey: credentialOptions });

      this.credentialHiddenInputTarget.value = JSON.stringify(credential);

      this.element.submit();
    } catch (error) {
      alert(error.message || error);
    }
  }
}
