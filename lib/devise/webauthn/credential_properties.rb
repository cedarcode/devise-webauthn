# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialProperties
      private

      def credential_record_attributes(credential, discoverable: reported_discoverable?(credential))
        {
          external_id: credential.id,
          public_key: credential.public_key,
          sign_count: credential.sign_count,
          discoverable: discoverable,
          uv_initialized: credential.response.authenticator_data.user_verified?
        }
      end

      # The browser reports rk, so it is not signed. It is false when the browser does not report it.
      def reported_discoverable?(credential)
        outputs = credential.client_extension_outputs
        outputs.is_a?(Hash) && outputs["credProps"].is_a?(Hash) && outputs["credProps"]["rk"] == true
      end
    end
  end
end
