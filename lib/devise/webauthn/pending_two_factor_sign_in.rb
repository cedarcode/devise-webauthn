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

      # Browsers keep the `two_factor_token` in the session; API clients send it back as a param.
      def two_factor_sign_in_attempt_for(scope)
        TwoFactorToken.read(request.session[:two_factor_token], scope: scope) ||
          TwoFactorToken.read(params[:two_factor_token], scope: scope)
      end

      def consume_two_factor_sign_in_attempt(sign_in_attempt)
        request.session.delete(:two_factor_token)
        TwoFactorToken.consume(sign_in_attempt)
      end
    end
  end
end
