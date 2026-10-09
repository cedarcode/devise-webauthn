# frozen_string_literal: true

module Devise
  class PasskeyAuthenticationOptionsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess

    skip_forgery_protection if respond_to?(:skip_forgery_protection)

    def create
      passkey_options =
        WebAuthn::Credential.options_for_get(
          user_verification: "required"
        )

      render json: options_with_stored_challenge(:passkey_authentication, passkey_options)
    end
  end
end
