# frozen_string_literal: true

require "active_support/concern"
require "devise/models/webauthn_credential_authenticatable"
require "devise/strategies/passkey_authenticatable"

module Devise
  module Models
    module PasskeyAuthenticatable
      extend ActiveSupport::Concern
      include WebauthnCredentialAuthenticatable

      included do
        has_many :passkeys, -> { passkey }, class_name: "WebauthnCredential"
      end
    end
  end
end
