# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialsHelper
      def create_passkey_form(resource:, form_classes: nil, &block)
        form_with(
          url: passkeys_path(resource),
          method: :post,
          class: form_classes,
          data: {
            action: "webauthn-credentials#create:prevent",
            controller: "webauthn-credentials",
            webauthn_credentials_options_param: create_passkey_options(resource)
          }
        ) do |f|
          concat f.hidden_field(:public_key_credential,
                                data: { "webauthn-credentials-target": "credentialHiddenInput" })
          concat capture(f, &block)
        end
      end

      def login_with_passkey_button(text = nil, session_path:, button_classes: nil, form_classes: nil, &block)
        form_with(
          url: session_path,
          method: :post,
          data: {
            action: "webauthn-credentials#get:prevent",
            controller: "webauthn-credentials",
            webauthn_credentials_options_param: webauthn_authentication_options
          },
          class: form_classes
        ) do |f|
          concat f.hidden_field(:public_key_credential,
                                data: { "webauthn-credentials-target": "credentialHiddenInput" })
          concat f.button(text, type: "submit", class: button_classes, &block)
        end
      end

      private

      def create_passkey_options(resource)
        @create_passkey_options ||= begin
          options = WebAuthn::Credential.options_for_create(
            user: {
              id: resource.webauthn_id,
              name: resource.email
            },
            exclude: resource.passkeys.pluck(:external_id),
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
    end
  end
end
