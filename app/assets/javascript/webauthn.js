export class WebauthnCreateElement extends HTMLElement {
  connectedCallback() {
    this.closest('form').addEventListener('submit', async (event) => {
      event.preventDefault();

      try {
        const options = JSON.parse(this.getAttribute('data-options-json'));
        const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(options);
        const credential = await navigator.credentials.create({ publicKey });

        this.querySelector('.js-webauthn-response').value = JSON.stringify(credential);

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
}

export class WebauthnGetElement extends HTMLElement {
  connectedCallback() {
    this.closest('form').addEventListener('submit', async (event) => {
      event.preventDefault();

      try {
        const options = JSON.parse(this.getAttribute('data-options-json'));
        const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(options);
        const credential = await navigator.credentials.get({ publicKey });

        this.querySelector('.js-webauthn-response').value = JSON.stringify(credential);

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
}

customElements.define('webauthn-create', WebauthnCreateElement);
customElements.define('webauthn-get', WebauthnGetElement);
