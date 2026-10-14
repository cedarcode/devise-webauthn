# frozen_string_literal: true

module Devise
  module Webauthn
    module PendingTwoFactorSignIn
      private

      def start_two_factor_sign_in_attempt_for(resource, scope:, remember_me:)
        request.session[:two_factor_token] = TwoFactorToken.generate(resource, scope: scope, remember_me: remember_me)
      end

      def two_factor_sign_in_attempt_for(scope)
        TwoFactorToken.read(request.session[:two_factor_token], scope: scope)
      end

      def clear_two_factor_sign_in_attempt
        request.session.delete(:two_factor_token)
      end
    end
  end
end
