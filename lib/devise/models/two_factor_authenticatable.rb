# frozen_string_literal: true

require "active_support/concern"
require "devise/hooks/two_factor_authenticatable"
require "devise/strategies/two_factor_authenticatable"

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern

      def second_factor_enabled?
        true
      end
    end
  end
end
