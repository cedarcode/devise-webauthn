# frozen_string_literal: true

require "active_support/concern"

module Devise
  module Models
    module PasskeyAuthenticatable
      extend ActiveSupport::Concern

      included do
        has_many :passkeys, dependent: :destroy

        validates :webauthn_id, uniqueness: true, allow_blank: true
      end
    end
  end
end
