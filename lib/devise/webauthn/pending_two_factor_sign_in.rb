# frozen_string_literal: true

module Devise
  module Webauthn
    module PendingTwoFactorSignIn
      private

      # Browsers keep the pending sign-in in the session; API clients send back the `two_factor_token`.
      def pending_two_factor_sign_in(scope)
        resource_id = request.session[:current_authentication_resource_id]
        if resource_id.present?
          { "id" => resource_id, "remember_me" => request.session[:current_authentication_remember_me] }
        else
          TwoFactorToken.read(params[:two_factor_token], scope: scope)
        end
      end

      def clear_pending_two_factor_sign_in
        request.session.delete(:current_authentication_resource_id)
        request.session.delete(:current_authentication_remember_me)
      end
    end
  end
end
