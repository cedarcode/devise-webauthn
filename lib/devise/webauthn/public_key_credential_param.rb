# frozen_string_literal: true

module Devise
  module Webauthn
    module PublicKeyCredentialParam
      # Browser forms send the credential as a JSON string; API clients send it as a JSON object.
      def self.parse(value)
        value = JSON.parse(value) if value.is_a?(String)
        # Controller params are ActionController::Parameters, not a Hash. Strong parameters are not
        # needed: WebAuthn only verifies the credential, and nothing assigns it to a model.
        value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
        value if value.is_a?(Hash)
      rescue JSON::ParserError
        nil
      end

      private

      def public_key_credential_param
        PublicKeyCredentialParam.parse(params[:public_key_credential])
      end
    end
  end
end
