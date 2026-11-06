# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialProperties
      private

      def credential_record_attributes(credential)
        {
          external_id: credential.id,
          public_key: credential.public_key,
          sign_count: credential.sign_count,
          discoverable: reported_discoverable(credential),
          uv_initialized: credential.response.authenticator_data.user_verified?
        }
      end

      # The browser reports rk, so it is not signed. It is nil when the browser does not know.
      def reported_discoverable(credential)
        outputs = credential.client_extension_outputs
        return unless outputs.is_a?(Hash) && outputs["credProps"].is_a?(Hash)

        rk = outputs["credProps"]["rk"]
        rk if [true, false].include?(rk)
      end
    end
  end
end
