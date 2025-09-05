# frozen_string_literal: true

module Devise
  module Webauthn
    module PasskeysHelper
      def create_passkey_form(form_classes: nil, &block)
        form_with(
          url: passkeys_path,
          method: :post,
          class: form_classes,
          data: {
            action: "passkeys#create:prevent",
            controller: "passkeys",
            passkeys_options_param: create_passkey_options
          }
        ) do |f|
          concat f.hidden_field(:passkey_public_key, data: { "passkeys-target": "hiddenPasskeyPublicKeyInput" })
          concat capture(f, &block)
        end
      end

      private

      def create_passkey_options
        @create_passkey_options ||= begin
          options = WebAuthn::Credential.options_for_create(
            user: {
              id: current_user.webauthn_id,
              name: current_user.email
            },
            exclude: current_user.passkeys.pluck(:external_id),
            authenticator_selection: {
              resident_key: "required",
              user_verification: "required"
            }
          )

          # Store challenge in session for later verification
          session[:webauthn_challenge] = options.challenge

          options
        end
      end

      def passkeys_path
        public_send("#{resource_name}_passkeys_path")
      end
    end
  end
end
