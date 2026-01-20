# frozen_string_literal: true

module Devise
  module Passkey
    class RegistrationOptionsController < DeviseController
      before_action :authenticate_scope!

      def index
        passkey_options =
          WebAuthn::Credential.options_for_create(
            user: {
              id: resource.webauthn_id,
              name: resource_human_palatable_identifier
            },
            exclude: resource.passkeys.pluck(:external_id),
            authenticator_selection: {
              resident_key: "required",
              user_verification: "required"
            }
          )

        # Store challenge in session for later verification
        session[:webauthn_challenge] = passkey_options.challenge

        render json: passkey_options
      end

      private

      def authenticate_scope!
        send(:"authenticate_#{resource_name}!", force: true)
        self.resource = send(:"current_#{resource_name}")
      end

      def resource_human_palatable_identifier
        authentication_keys = resource.class.authentication_keys
        authentication_keys = authentication_keys.keys if authentication_keys.is_a?(Hash)

        authentication_keys.filter_map { |authentication_key| resource.public_send(authentication_key) }.first
      end
    end
  end
end
