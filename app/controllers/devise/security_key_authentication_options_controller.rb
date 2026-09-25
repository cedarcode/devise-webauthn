# frozen_string_literal: true

module Devise
  class SecurityKeyAuthenticationOptionsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PendingTwoFactorSignIn

    skip_forgery_protection if respond_to?(:skip_forgery_protection)

    before_action :set_resource

    def create
      security_key_authentication_options =
        WebAuthn::Credential.options_for_get(
          allow: @resource.webauthn_credentials.pluck(:external_id),
          user_verification: "discouraged"
        )

      challenge_store.write(:two_factor_authentication, security_key_authentication_options.challenge)

      render json: security_key_authentication_options
    end

    private

    def set_resource
      @resource = resource_class.find(pending_two_factor_sign_in(resource_name)&.fetch("id"))
    end
  end
end
