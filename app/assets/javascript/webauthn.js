export class WebauthnGetElement extends HTMLElement {
  constructor() {
    super();
  }

  connectedCallback() {
    this.closest('form').addEventListener('submit', async (event) => {
      event.preventDefault();

      try {
        const options = JSON.parse(this.getAttribute('get-options'));
        const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(options);
        const credential = await navigator.credentials.get({ publicKey });

        this.querySelector('.js-webauthn-response').value = JSON.stringify(credential);

        this.closest('form').submit();
      } catch (error) {
        alert(error.message || error);
      }
    });
  }
}

customElements.define('webauthn-get', WebauthnGetElement);
