import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["credentialHiddenInput"]

  async create({ params: { optionsUrl } }) {
    try {
      const response = await fetch(optionsUrl);

      const credentialOptions = PublicKeyCredential.parseCreationOptionsFromJSON(await response.json());
      const credential = await navigator.credentials.create({ publicKey: credentialOptions });

      this.credentialHiddenInputTarget.value = JSON.stringify(credential);

      this.element.submit();
    } catch (error) {
      alert(error.message || error);
    }
  }

  async get({ params: { optionsUrl } }) {
    try {
      const response = await fetch(optionsUrl);

      const credentialOptions = PublicKeyCredential.parseRequestOptionsFromJSON(await response.json());
      const credential = await navigator.credentials.get({ publicKey: credentialOptions });

      this.credentialHiddenInputTarget.value = JSON.stringify(credential);

      this.element.submit();
    } catch (error) {
      alert(error.message || error);
    }
  }
}
