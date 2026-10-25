# frozen_string_literal: true

module Devise
  class SecurityKeyUpgradeOptionsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess

    skip_forgery_protection if respond_to?(:skip_forgery_protection)

    before_action :authenticate_scope!

    # The same options as passkey sign-in, so only a security key that can sign in as a passkey answers them.
    def create
      security_key_upgrade_options =
        WebAuthn::Credential.options_for_get(
          user_verification: "required"
        )

      challenge_store.write(:security_key_upgrade, security_key_upgrade_options.challenge)

      render json: security_key_upgrade_options
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end
  end
end
