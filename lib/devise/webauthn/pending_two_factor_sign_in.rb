# frozen_string_literal: true

module Devise
  module Webauthn
    module PendingTwoFactorSignIn
      include StateStoreAccess

      private

      def store_two_factor_sign_in_attempt_in_session(resource, scope:, remember_me:)
        request.session[:two_factor_token] =
          two_factor_sign_in_attempt_token_for(resource, scope: scope, remember_me: remember_me)
      end

      def two_factor_sign_in_attempt_token_for(resource, scope:, remember_me:)
        jti = SecureRandom.uuid
        state_store.issue_two_factor_token(jti)
        TwoFactorToken.generate(resource, scope: scope, remember_me: remember_me, jti: jti)
      end

      # Browsers keep the `two_factor_token` in the session; API clients send it back as a param.
      def two_factor_sign_in_attempt_for(scope)
        sign_in_attempt = TwoFactorToken.read(request.session[:two_factor_token], scope: scope) ||
                          TwoFactorToken.read(params[:two_factor_token], scope: scope)
        sign_in_attempt if sign_in_attempt && state_store.two_factor_token_issued?(sign_in_attempt["jti"])
      end

      def consume_two_factor_sign_in_attempt(sign_in_attempt)
        request.session.delete(:two_factor_token)
        state_store.consume_two_factor_token(sign_in_attempt["jti"])
      end
    end
  end
end
