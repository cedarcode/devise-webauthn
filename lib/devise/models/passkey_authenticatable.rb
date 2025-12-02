# frozen_string_literal: true

require "active_support/concern"
require "devise/strategies/passkey_authenticatable"

module Devise
  module Models
    module PasskeyAuthenticatable
      extend ActiveSupport::Concern

      included do
        has_many :passkeys, dependent: :destroy, class_name: "WebauthnCredential"

        validates :webauthn_id, uniqueness: true, allow_blank: true

        after_initialize do
          self.webauthn_id ||= WebAuthn.generate_user_id
        end
      end

      module ClassMethods
        def find_for_passkey_authentication(passkey)
          passkey.public_send(name.underscore)
        end
      end
    end
  end
end
