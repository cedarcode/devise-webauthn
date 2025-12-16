import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["credentialHiddenInput"]

  async create({ params: { optionsUrl } }) {
    try {
      const response = await fetch(optionsUrl);

      const parsedResponse = await response.json();
      const credentialOptions = PublicKeyCredential.parseCreationOptionsFromJSON(parsedResponse);
      const credential = await navigator.credentials.create({ publicKey: credentialOptions });

      this.credentialHiddenInputTarget.value = JSON.stringify(credential);

      queueMicrotask(() => this.element.requestSubmit());
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

      queueMicrotask(() => this.element.requestSubmit());
    } catch (error) {
      alert(error.message || error);
    }
  }
}
