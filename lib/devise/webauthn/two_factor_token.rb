# frozen_string_literal: true

module Devise
  module Webauthn
    class TwoFactorToken
      PURPOSE = :devise_webauthn_two_factor

      cattr_accessor :expires_in, default: 5.minutes

      def self.generate(resource, scope:, remember_me:)
        payload = { "id" => resource.id, "scope" => scope.to_s, "remember_me" => remember_me }
        verifier.generate(payload, purpose: PURPOSE, expires_in: expires_in)
      end

      def self.read(token, scope:)
        return unless token.is_a?(String)

        payload = verifier.verified(token, purpose: PURPOSE)
        payload if payload.is_a?(Hash) && payload["scope"] == scope.to_s
      end

      def self.verifier
        Rails.application.message_verifier(PURPOSE)
      end
    end
  end
end
