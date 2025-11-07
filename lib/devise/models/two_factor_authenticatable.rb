# frozen_string_literal: true

require "active_support/concern"

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern

      def after_database_authentication
        throw :warden, scope: Devise::Mapping.find_scope!(self), message: "two_factor_required"
      end
    end
  end
end
