# frozen_string_literal: true

require "active_support/concern"

module Devise
  module Models
    module WebauthnCredentialAuthenticatable
      extend ActiveSupport::Concern

      included do
        has_many :webauthn_credentials, dependent: :destroy

        validates :webauthn_id, uniqueness: true, allow_blank: true

        after_initialize do
          self.webauthn_id ||= WebAuthn.generate_user_id
        end
      end
    end
  end
end
