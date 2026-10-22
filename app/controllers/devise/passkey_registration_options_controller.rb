# frozen_string_literal: true

module Devise
  class PasskeyRegistrationOptionsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess

    skip_forgery_protection if respond_to?(:skip_forgery_protection)

    before_action :authenticate_scope!
    before_action :ensure_webauthn_id!

    def create
      passkey_options =
        WebAuthn::Credential.options_for_create(
          user: {
            id: resource.webauthn_id,
            name: resource.webauthn_user_name
          },
          exclude: resource.passkeys.pluck(:external_id),
          authenticator_selection: {
            resident_key: "required",
            # WebAuthn Level 1 clients read this instead of `resident_key`.
            require_resident_key: true,
            user_verification: "required"
          }
        )

      challenge_store.write(:registration, passkey_options.challenge)

      render json: passkey_options
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end

    def ensure_webauthn_id!
      resource.ensure_webauthn_id!
    end
  end
end
