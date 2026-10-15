# frozen_string_literal: true

module Devise
  module Webauthn
    module StateStores
      class Cache
        cattr_accessor :cache
        cattr_accessor :expires_in, default: 5.minutes

        def initialize(request)
          @request = request
        end

        def write(purpose, challenge)
          store.write(key(purpose, challenge), true, expires_in: expires_in)
        end

        def pending?(purpose)
          challenge.present? && store.exist?(key(purpose, challenge))
        end

        # `exist?` honours expiry, which MemoryStore#delete does not. `delete` decides which concurrent request wins.
        def consume(purpose)
          return if challenge.blank?
          return unless store.exist?(key(purpose, challenge))
          return unless store.delete(key(purpose, challenge))

          challenge
        end

        def issue_two_factor_token(jti)
          store.write(two_factor_token_key(jti), true, expires_in: TwoFactorToken.expires_in)
        end

        def two_factor_token_issued?(jti)
          store.exist?(two_factor_token_key(jti))
        end

        # `delete` returns true for one caller only, so a token finishes one sign-in.
        def consume_two_factor_token(jti)
          jti if store.delete(two_factor_token_key(jti))
        end

        private

        def store
          cache || Rails.cache
        end

        def key(purpose, challenge)
          "devise_webauthn:challenge:#{purpose}:#{Digest::SHA256.hexdigest(challenge)}"
        end

        def two_factor_token_key(jti)
          "devise_webauthn:two_factor_token:#{jti}"
        end

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
