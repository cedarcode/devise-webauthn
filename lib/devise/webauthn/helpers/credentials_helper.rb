# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialsHelper
      def passkey_creation_form_for(resource_or_resource_name, **options, &block)
        form_with(
          **options.merge(url: passkeys_path(resource_or_resource_name), method: :post)
        ) do |f|
          tag.webauthn_create(data: { options_url: passkey_registration_options_path(resource_or_resource_name) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def login_with_passkey_form_for(resource_or_resource_name, **options, &block)
        form_with(
          **options.merge(url: session_path(resource_or_resource_name), method: :post)
        ) do |f|
          tag.webauthn_get(data: { options_url: passkey_authentication_options_path(resource_or_resource_name) }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def security_key_creation_form_for(resource_or_resource_name, **options, &block)
        form_with(
          **options.merge(url: second_factor_webauthn_credentials_path(resource_or_resource_name), method: :post)
        ) do |f|
          tag.webauthn_create(
            data: { options_url: security_key_registration_options_path(resource_or_resource_name) }
          ) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end

      def login_with_security_key_form_for(resource_or_resource_name, **options, &block)
        form_with(
          **options.merge(url: two_factor_authentication_path(resource_or_resource_name), method: :post)
        ) do |f|
          tag.webauthn_get(data: {
                             options_url: security_key_authentication_options_path(resource_or_resource_name)
                           }) do
            concat f.hidden_field(:public_key_credential, data: { webauthn_target: "response" })
            concat capture(f, &block)
          end
        end
      end
    end
  end
end
