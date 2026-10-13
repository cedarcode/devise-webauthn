# frozen_string_literal: true

module Devise
  class SecurityKeyAuthenticationOptionsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PendingTwoFactorSignIn

    skip_forgery_protection

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
      pending_sign_in = pending_two_factor_sign_in(resource_name)
      throw :warden, scope: resource_name, message: :sign_in_not_initiated if pending_sign_in.blank?

      @resource = resource_class.find(pending_sign_in["id"])
    end
  end
end
