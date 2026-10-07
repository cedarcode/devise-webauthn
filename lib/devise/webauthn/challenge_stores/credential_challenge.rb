# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStores
      module CredentialChallenge
        private

        def challenge
          return @challenge if defined?(@challenge)

          @challenge = begin
            client_data_json = credential.dig("response", "clientDataJSON") if credential.is_a?(Hash)
            client_data = WebAuthn::ClientData.new(encoder.decode(client_data_json)) if client_data_json.is_a?(String)
            encoder.encode(client_data.challenge) if client_data
          rescue JSON::ParserError, ArgumentError, TypeError, EncodingError, NoMethodError
            nil
          end
        end

        def credential
          @credential ||= PublicKeyCredentialParam.parse(@request.params[:public_key_credential])
        end

        def encoder
          WebAuthn.configuration.encoder
        end
      end
    end
  end
end
