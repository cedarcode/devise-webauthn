# frozen_string_literal: true

require "active_support/concern"
require "devise/models/webauthn_credential_authenticatable"
require "devise/strategies/two_factor_authenticatable"

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern
      include WebauthnCredentialAuthenticatable

      included do
        has_many :second_factor_webauthn_credentials, -> { second_factor }, class_name: "WebauthnCredential"
      end

      def second_factor_enabled?
        webauthn_credentials.any?
      end
    end
  end
end
