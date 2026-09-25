# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStores
      class Cache
        cattr_accessor :cache
        cattr_accessor :expires_in, default: 5.minutes

        def initialize(_request); end

        def write(purpose, challenge)
          store.write(key(purpose, challenge), true, expires_in: expires_in)
        end

        def pending?(purpose, credential)
          challenge = challenge_from(credential)
          challenge.present? && store.exist?(key(purpose, challenge))
        end

        # `exist?` honours expiry, which MemoryStore#delete does not. `delete` decides which concurrent request wins.
        def consume(purpose, credential)
          challenge = challenge_from(credential)
          return if challenge.blank?

          challenge if store.exist?(key(purpose, challenge)) && store.delete(key(purpose, challenge))
        end

        private

        def store
          cache || Rails.cache
        end

        def key(purpose, challenge)
          "devise_webauthn:challenge:#{purpose}:#{challenge}"
        end

        def challenge_from(credential)
          client_data_json = credential.dig("response", "clientDataJSON") if credential.is_a?(Hash)
          return unless client_data_json.is_a?(String)

          client_data = JSON.parse(encoder.decode(client_data_json))
          challenge = client_data["challenge"] if client_data.is_a?(Hash)
          encoder.encode(WebAuthn.standard_encoder.decode(challenge)) if challenge.is_a?(String)
        rescue JSON::ParserError, ArgumentError, TypeError, EncodingError
          nil
        end

        def encoder
          WebAuthn.configuration.encoder
        end
      end
    end
  end
end
