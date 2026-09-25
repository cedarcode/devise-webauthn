# frozen_string_literal: true

module Devise
  module Webauthn
    module PublicKeyCredentialParam
      private

      # Browser forms send the credential as a JSON string; API clients send it as a JSON object.
      def public_key_credential_param
        value = params[:public_key_credential]
        value = JSON.parse(value) if value.is_a?(String)
        value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
        value if value.is_a?(Hash)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
