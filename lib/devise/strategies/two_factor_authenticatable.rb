# frozen_string_literal: true

module Devise
  module Strategies
    class TwoFactorAuthenticatable < Warden::Strategies::Base
      def authenticate!; end

      def validate_security_key(resource); end
    end
  end
end

Warden::Strategies.add(:two_factor_authenticatable, Devise::Strategies::TwoFactorAuthenticatable)
