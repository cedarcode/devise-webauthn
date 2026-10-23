# frozen_string_literal: true

require "active_support/concern"

module Devise
  module Models
    module WebauthnCredentialAuthenticatable
      extend ActiveSupport::Concern

      included do
        has_many :webauthn_credentials, dependent: :destroy

        validates :webauthn_id, uniqueness: true, allow_blank: true
      end

      def ensure_webauthn_id!
        return webauthn_id if webauthn_id.present?

        self.webauthn_id = WebAuthn.generate_user_id
        save!(validate: false)

        webauthn_id
      end

      # WebAuthn `user.name` and `displayName`, which the browser or OS shows for the credential. Defaults to
      # the first authentication key with a non-nil value. Override it when that key is nil on a saved record.
      def webauthn_user_name
        authentication_keys = self.class.authentication_keys
        authentication_keys = authentication_keys.keys if authentication_keys.is_a?(Hash)

        authentication_keys.filter_map { |authentication_key| public_send(authentication_key) }.first
      end
    end
  end
end
