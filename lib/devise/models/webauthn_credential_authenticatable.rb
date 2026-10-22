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

      # The account name an authenticator shows for a new credential (WebAuthn `user.name`). Defaults to the
      # first present authentication key, then `email`. Override it when an authentication key is virtual,
      # such as a `login` that accepts a username or an email.
      def webauthn_user_name
        authentication_keys = self.class.authentication_keys
        authentication_keys = authentication_keys.keys if authentication_keys.is_a?(Hash)
        name = (authentication_keys + [:email]).lazy.select { |key| respond_to?(key) }
                                               .map { |key| public_send(key) }.find(&:present?)

        (name || to_param).to_s
      end

      # The friendly name an authenticator shows for a new credential (WebAuthn `user.displayName`).
      def webauthn_display_name
        webauthn_user_name
      end
    end
  end
end
