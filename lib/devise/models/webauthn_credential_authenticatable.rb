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

        update_column(:webauthn_id, WebAuthn.generate_user_id) # rubocop:disable Rails/SkipsModelValidations
        webauthn_id
      end
    end
  end
end
