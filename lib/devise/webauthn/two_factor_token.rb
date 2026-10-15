# frozen_string_literal: true

module Devise
  module Webauthn
    class TwoFactorToken
      PURPOSE = :devise_webauthn_two_factor

      cattr_accessor :expires_in, default: 5.minutes

      def self.generate(resource, scope:, remember_me:)
        payload = { "id" => resource.id, "scope" => scope.to_s, "remember_me" => remember_me }
        encryptor.encrypt_and_sign(payload, purpose: PURPOSE, expires_in: expires_in)
      end

      def self.read(token, scope:)
        return unless token.is_a?(String)

        payload = encryptor.decrypt_and_verify(token, purpose: PURPOSE)
        payload if payload.is_a?(Hash) && payload["scope"] == scope.to_s
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        nil
      end

      # A fixed serializer, so a change to the app's message serializer does not make issued tokens raise.
      def self.encryptor
        key = Rails.application.key_generator.generate_key(PURPOSE.to_s, ActiveSupport::MessageEncryptor.key_len)
        ActiveSupport::MessageEncryptor.new(key, serializer: JSON)
      end
    end
  end
end
