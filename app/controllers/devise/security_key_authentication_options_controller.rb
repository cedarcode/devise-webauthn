# frozen_string_literal: true

module Devise
  class SecurityKeyAuthenticationOptionsController < DeviseController
    before_action :set_resource

    def index
      security_key_authentication_options =
        WebAuthn::Credential.options_for_get(
          allow: @resource.webauthn_credentials.pluck(:external_id),
          user_verification: "discouraged"
        )

      # Store challenge in session for later verification
      session[:two_factor_authentication_challenge] = security_key_authentication_options.challenge

      render json: security_key_authentication_options
    end

    private

    def set_resource
      @resource = resource_class.find(session[:current_authentication_resource_id])
    end
  end
end
