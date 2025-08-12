# frozen_string_literal: true

module Devise
  module Webauthn
    module PasskeysHelper
      # WebAuthn error messages hash for JavaScript integration
      def webauthn_error_messages
        @webauthn_error_messages ||= {
          not_allowed: t("devise.webauthn.webauthn_errors.not_allowed"),
          invalid_state: t("devise.webauthn.webauthn_errors.invalid_state"),
          security_error: t("devise.webauthn.webauthn_errors.security_error"),
          not_supported: t("devise.webauthn.webauthn_errors.not_supported"),
          aborted: t("devise.webauthn.webauthn_errors.aborted")
        }.freeze
      end

      # WebAuthn options for passkey authentication (login)
      def webauthn_authentication_options
        @webauthn_authentication_options ||= begin
          options = WebAuthn::Credential.options_for_get(
            user_verification: "required"
          )

          # Store challenge in session for later verification
          session[:authentication_challenge] = options.challenge

          options
        end
      end

      # WebAuthn options for passkey creation
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

      def create_passkey_form(form_classes: nil, &block)
        raise ArgumentError, "Block is required for create_passkey_form" unless block_given?

        form_with(
          url: main_app.passkeys_path,
          method: :post,
          local: true,
          class: form_classes,
          data: {
            action: "passkeys#create:prevent",
            controller: "passkeys",
            passkeys_options_param: create_passkey_options,
            passkeys_error_messages_value: webauthn_error_messages.to_json
          }
        ) do |f|
          concat f.hidden_field(:passkey_public_key, data: { "passkeys-target": "hiddenPasskeyPublicKeyInput" })
          concat capture(f, &block)
        end
      end

      def login_with_passkey_button(text = nil, button_classes: nil, form_classes: nil, &block)
        form_with(
          model: resource,
          url: main_app.user_session_path,
          method: :post,
          local: true,
          data: {
            action: "passkeys#get:prevent",
            controller: "passkeys",
            passkeys_options_param: webauthn_authentication_options,
            passkeys_error_messages_value: webauthn_error_messages.to_json
          },
          class: form_classes
        ) do |f|
          concat f.hidden_field(:passkey_public_key, data: { "passkeys-target": "hiddenPasskeyPublicKeyInput" })
          concat f.button(text, type: "submit", class: button_classes, &block)
        end
      end
    end
  end
end
