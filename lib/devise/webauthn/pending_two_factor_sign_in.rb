# frozen_string_literal: true

module Devise
  module Webauthn
    module PendingTwoFactorSignIn
      private

      def store_two_factor_sign_in_attempt_in_session(resource, scope:, remember_me:)
        request.session[:two_factor_token] =
          two_factor_sign_in_attempt_token_for(resource, scope: scope, remember_me: remember_me)
      end

      def two_factor_sign_in_attempt_token_for(resource, scope:, remember_me:)
        TwoFactorToken.generate(resource, scope: scope, remember_me: remember_me)
      end

      # Browsers keep the `two_factor_token` in the session; API clients send it in the request body.
      # The query string is ignored because servers and proxies log URLs.
      def two_factor_sign_in_attempt_for(scope)
        @two_factor_sign_in_attempts ||= {}
        return @two_factor_sign_in_attempts[scope] if @two_factor_sign_in_attempts.key?(scope)

        @two_factor_sign_in_attempts[scope] =
          TwoFactorToken.read(request.session[:two_factor_token], scope: scope) ||
          TwoFactorToken.read(request.request_parameters["two_factor_token"], scope: scope)
      end

      def clear_two_factor_sign_in_attempt
        @two_factor_sign_in_attempts = nil
        request.session.delete(:two_factor_token)
      end
    end
  end
end
