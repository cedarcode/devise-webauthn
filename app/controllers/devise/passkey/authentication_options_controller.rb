# frozen_string_literal: true

module Devise
  module Passkey
    class AuthenticationOptionsController < DeviseController
      def index
        passkey_options =
          WebAuthn::Credential.options_for_get(
            user_verification: "required"
          )

        # Store challenge in session for later verification
        session[:authentication_challenge] = passkey_options.challenge

        render json: passkey_options
      end
    end
  end
end
