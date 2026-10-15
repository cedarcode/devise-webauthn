# frozen_string_literal: true

module Devise
  module Webauthn
    class TwoFactorToken
      PURPOSE = :devise_webauthn_two_factor

      cattr_accessor :expires_in, default: 5.minutes

      def self.generate(resource, scope:, remember_me:)
        payload = { "id" => resource.id, "scope" => scope.to_s, "remember_me" => remember_me,
                    "jti" => SecureRandom.uuid }
        cache.write(cache_key(payload), true, expires_in: expires_in) if cached?
        verifier.generate(payload, purpose: PURPOSE, expires_in: expires_in)
      end

      def self.read(token, scope:)
        return unless token.is_a?(String)

        payload = verifier.verified(token, purpose: PURPOSE)
        return unless payload.is_a?(Hash) && payload["scope"] == scope.to_s
        return if cached? && !cache.exist?(cache_key(payload))

        payload
      end

      # With the cache store, only the first caller gets true, so a token finishes one sign-in.
      def self.consume(payload)
        !cached? || cache.delete(cache_key(payload))
      end

      # A fixed serializer, so a change to the app's message serializer does not make issued tokens raise.
      def self.verifier
        ActiveSupport::MessageVerifier.new(Rails.application.key_generator.generate_key(PURPOSE.to_s),
                                           digest: "SHA256", serializer: JSON)
      end

      def self.cached?
        store = Devise::Webauthn.state_store
        store == :cache || (store.is_a?(Class) && store <= StateStores::Cache)
      end

      def self.cache
        StateStores::Cache.cache || Rails.cache
      end

      def self.cache_key(payload)
        "devise_webauthn:two_factor_token:#{payload['jti']}"
      end

      private_class_method :cached?, :cache, :cache_key
    end
  end
end
