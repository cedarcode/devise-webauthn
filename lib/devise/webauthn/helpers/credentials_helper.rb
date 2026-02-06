# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Devise
  module Webauthn
    module CredentialsHelper
      def passkey_creation_form_for(resource_or_resource_name, form_classes: nil, &block)
        form_with(
          url: passkeys_path(resource_or_resource_name),
          method: :post,
          class: form_classes
        ) do |f|
          tag.webauthn_create(data: { options_url: passkey_registration_options_path(resource_or_resource_name) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def login_with_passkey_button_for(resource_or_resource_name, text = nil, session_path:, button_classes: nil,
                                        form_classes: nil, &block)
        form_with(
          url: session_path,
          method: :post,
          class: form_classes
        ) do |f|
          tag.webauthn_get(data: { options_url: passkey_authentication_options_path(resource_or_resource_name) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })

            concat f.button(text, type: "submit", class: button_classes, &block)
          end
        end
      end

      def security_key_creation_form_for(resource_or_resource_name, form_classes: nil, &block)
        form_with(
          url: second_factor_webauthn_credentials_path(resource_or_resource_name),
          method: :post,
          class: form_classes
        ) do |f|
          tag.webauthn_create(
            data: { options_url: security_key_registration_options_path(resource_or_resource_name) }
          ) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def login_with_security_key_button_for(resource_or_resource_name, text = nil, button_classes: nil,
                                             form_classes: nil, &block)
        form_with(
          url: two_factor_authentication_path(resource_or_resource_name),
          method: :post,
          class: form_classes
        ) do |f|
          tag.webauthn_get(data: {
                             options_url: security_key_authentication_options_path(resource_or_resource_name)
                           }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat f.button(text, type: "submit", class: button_classes, &block)
          end
        end
      end

      def create_passkey_options(resource)
        @create_passkey_options ||= begin
          options = WebAuthn::Credential.options_for_create(
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
          session[:webauthn_challenge] = options.challenge

          options
        end
      end

      def passkey_authentication_options
        @passkey_authentication_options ||= begin
          options = WebAuthn::Credential.options_for_get(
            user_verification: "required"
          )

          # Store challenge in session for later verification
          session[:authentication_challenge] = options.challenge

          options
        end
      end

      def create_security_key_options(resource)
        @create_security_key_options ||= begin
          options = WebAuthn::Credential.options_for_create(
            user: {
              id: resource.webauthn_id,
              name: resource_human_palatable_identifier
            },
            exclude: resource.webauthn_credentials.pluck(:external_id),
            authenticator_selection: {
              resident_key: "discouraged",
              user_verification: "discouraged"
            }
          )

          # Store challenge in session for later verification
          session[:webauthn_challenge] = options.challenge

          options
        end
      end

      def security_key_authentication_options(resource)
        @security_key_authentication_options ||= begin
          options = WebAuthn::Credential.options_for_get(
            allow: resource.webauthn_credentials.pluck(:external_id),
            user_verification: "discouraged"
          )

          # Store challenge in session for later verification
          session[:two_factor_authentication_challenge] = options.challenge

          options
        end
      end

      private

      def resource_human_palatable_identifier
        authentication_keys = resource.class.authentication_keys
        authentication_keys = authentication_keys.keys if authentication_keys.is_a?(Hash)

        authentication_keys.filter_map { |authentication_key| resource.public_send(authentication_key) }.first
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
