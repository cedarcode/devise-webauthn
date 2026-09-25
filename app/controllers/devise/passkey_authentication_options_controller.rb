# frozen_string_literal: true

module Devise
  class PasskeyAuthenticationOptionsController < DeviseController
    skip_forgery_protection

    def create
      passkey_options =
        WebAuthn::Credential.options_for_get(
          user_verification: "required"
        )

      Devise::Webauthn.challenge_store_for(request).write(:passkey_authentication, passkey_options.challenge)

      render json: passkey_options
    end
  end
end
