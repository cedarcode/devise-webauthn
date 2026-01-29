# frozen_string_literal: true

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

      def login_with_passkey_form_for(resource_or_resource_name, form_classes: nil, &block)
        form_with(
          url: session_path(resource_or_resource_name),
          method: :post,
          class: form_classes
        ) do |f|
          tag.webauthn_get(data: { options_url: passkey_authentication_options_path(resource_or_resource_name) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
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

      def login_with_security_key_form_for(resource_or_resource_name, form_classes: nil, &block)
        form_with(
          url: two_factor_authentication_path(resource_or_resource_name),
          method: :post,
          class: form_classes
        ) do |f|
          tag.webauthn_get(data: {
                             options_url: security_key_authentication_options_path(resource_or_resource_name)
                           }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
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
