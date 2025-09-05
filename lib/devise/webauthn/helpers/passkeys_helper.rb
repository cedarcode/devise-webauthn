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
            passkeys_options_param: @create_passkey_options
          }
        ) do |f|
          concat f.hidden_field(:passkey_public_key, data: { "passkeys-target": "hiddenPasskeyPublicKeyInput" })
          concat capture(f, &block)
        end
      end

      private

      def passkeys_path
        main_app.public_send("#{resource_name}_passkeys_path")
      end
    end
  end
end
