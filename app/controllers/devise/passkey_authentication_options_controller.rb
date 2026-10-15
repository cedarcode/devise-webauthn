# frozen_string_literal: true

module Devise
  class PasskeyAuthenticationOptionsController < DeviseController
    include Devise::Webauthn::StateStoreAccess

    skip_forgery_protection if respond_to?(:skip_forgery_protection)

    def create
      passkey_options =
        WebAuthn::Credential.options_for_get(
          user_verification: "required"
        )

      state_store.write(:passkey_authentication, passkey_options.challenge)

      render json: passkey_options
    end
  end
end
