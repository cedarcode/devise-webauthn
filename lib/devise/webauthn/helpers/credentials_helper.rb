# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialsHelper
      def passkey_creation_form_for(resource, form_classes: nil, &block)
        form_with(
          url: passkeys_path(resource),
          method: :post,
          class: form_classes,
          data: {
            controller: "webauthn-credentials",
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
            controller: "webauthn-credentials",
          },
          class: form_classes
        ) do |f|
          concat f.hidden_field(:public_key_credential,
                                data: { "webauthn-credentials-target": "credentialHiddenInput" })
          concat f.button(text,
                          type: "button",
                          class: button_classes,
                          data: { action: "webauthn-credentials#get",
                                  webauthn_credentials_options_url_param: options_for_get_passkeys_path(resource) },
                          &block)
        end
      end

      def security_key_creation_form_for(resource, form_classes: nil, &block)
        form_with(
          url: second_factor_webauthn_credentials_path(resource),
          method: :post,
          class: form_classes,
          data: {
            controller: "webauthn-credentials",
          }
        ) do |f|
          concat f.hidden_field(:public_key_credential,
                                data: { "webauthn-credentials-target": "credentialHiddenInput" })
          concat capture(f, &block)
        end
      end

      def login_with_security_key_button(text = nil, resource:, button_classes: nil, form_classes: nil, &block)
        form_with(
          url: two_factor_authentication_path(resource),
          method: :post,
          data: {
            controller: "webauthn-credentials",
          },
          class: form_classes
        ) do |f|
          concat f.hidden_field(:public_key_credential,
                                data: { "webauthn-credentials-target": "credentialHiddenInput" })
          concat f.button(text,
                          type: "button",
                          class: button_classes,
                          data: { action: "webauthn-credentials#get",
                                  webauthn_credentials_options_url_param: options_for_get_second_factor_webauthn_credentials_path(resource) },
                          &block)
        end
      end
    end
  end
end
