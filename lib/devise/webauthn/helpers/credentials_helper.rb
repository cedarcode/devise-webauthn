# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialsHelper
      def passkey_creation_form_for(resource, form_attributes: {}, &block)
        form_with(
          url: passkeys_path(resource),
          method: :post,
          **form_attributes
        ) do |f|
          tag.webauthn_create(data: { options_url: passkey_registration_options_path(resource) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def login_with_passkey_button(text = nil, session_path:, button_attributes: {}, form_attributes: {}, &block)
        form_with(
          url: session_path,
          method: :post,
          **form_attributes
        ) do |f|
          tag.webauthn_get(data: { options_url: passkey_authentication_options_path(resource) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })

            concat f.button(text, type: "submit", **button_attributes, &block)
          end
        end
      end

      def security_key_creation_form_for(resource, form_attributes: {}, &block)
        form_with(
          url: second_factor_webauthn_credentials_path(resource),
          method: :post,
          **form_attributes
        ) do |f|
          tag.webauthn_create(
            data: { options_url: security_key_registration_options_path(resource) }
          ) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def login_with_security_key_button(text = nil, resource:, button_attributes: {}, form_attributes: {}, &block)
        form_with(
          url: two_factor_authentication_path(resource),
          method: :post,
          **form_attributes
        ) do |f|
          tag.webauthn_get(data: { options_url: security_key_authentication_options_path(resource) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat f.button(text, type: "submit", **button_attributes, &block)
          end
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
