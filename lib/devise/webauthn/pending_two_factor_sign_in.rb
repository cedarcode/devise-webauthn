# frozen_string_literal: true

module Devise
  module Webauthn
    module PendingTwoFactorSignIn
      private

      def pending_two_factor_sign_in(scope)
        TwoFactorToken.read(request.session[:two_factor_token], scope: scope)
      end

      def clear_pending_two_factor_sign_in
        request.session.delete(:two_factor_token)
      end
    end
  end
end
