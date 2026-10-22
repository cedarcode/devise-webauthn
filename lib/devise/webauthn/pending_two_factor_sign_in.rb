# frozen_string_literal: true

module Devise
  module Webauthn
    module PendingTwoFactorSignIn
      private

      def start_two_factor_sign_in_attempt_for(resource, scope:, remember_me:)
        token = TwoFactorToken.generate(resource, scope: scope, remember_me: remember_me)
        request.session[:two_factor_token] = token if two_factor_token_stored_in_session?(scope)
        token
      end

      def two_factor_sign_in_attempt_for(scope)
        @two_factor_sign_in_attempts ||= {}
        return @two_factor_sign_in_attempts[scope] if @two_factor_sign_in_attempts.key?(scope)

        @two_factor_sign_in_attempts[scope] = TwoFactorToken.read(received_two_factor_token(scope), scope: scope)
      end

      def clear_two_factor_sign_in_attempt(scope)
        @two_factor_sign_in_attempts = nil
        request.session.delete(:two_factor_token) if two_factor_token_stored_in_session?(scope)
      end

      # Without session storage, clients send the `two_factor_token` in the request body.
      # The query string is ignored because servers and proxies log URLs.
      def received_two_factor_token(scope)
        if two_factor_token_stored_in_session?(scope)
          request.session[:two_factor_token]
        else
          request.request_parameters["two_factor_token"]
        end
      end

      # `devise.skip_storage` is Devise's per-request switch for what `skip_session_storage` does for every request.
      def two_factor_token_stored_in_session?(scope)
        !request.env["devise.skip_storage"] && Devise.mappings[scope].to.skip_session_storage.exclude?(:params_auth)
      end
    end
  end
end
