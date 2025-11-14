# frozen_string_literal: true

module Devise
  class SecondFactorAuthenticationController < DeviseController
    before_action :set_resource

    def new
      get_options = WebAuthn::Credential.options_for_get(
        allow: @resource.passkeys.pluck(:external_id),
        user_verification: "discouraged"
      )
      session[:two_factor_authentication_challenge] = get_options.challenge

      @options = get_options
    end

    private

    def set_resource
      @resource = resource_class.find(session[:current_authentication_resource_id])
    end
  end
end
