# frozen_string_literal: true

module Devise
  class SecondFactorAuthenticationController < DeviseController
    def new
      get_options = WebAuthn::Credential.options_for_get(
        allow: current_user.webauthn_credentials.pluck(:external_id),
        user_verification: "discouraged"
      )
      session[:current_authentication][:challenge] = get_options.challenge

      @options = get_options
    end
  end
end
