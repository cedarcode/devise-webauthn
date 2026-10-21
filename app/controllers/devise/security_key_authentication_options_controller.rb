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
      sign_in_attempt = two_factor_sign_in_attempt_for(resource_name)
      throw :warden, scope: resource_name, message: :sign_in_not_initiated if sign_in_attempt.blank?

      @resource = resource_class.find(sign_in_attempt["id"])
    end
  end
end
