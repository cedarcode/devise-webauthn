# frozen_string_literal: true

module Devise
  module Strategies
    class WebauthnTwoFactorAuthenticatable < Devise::Strategies::TwoFactor
      def valid?
        credential_param.present? &&
          session[:devise_two_factor_resource_id].present? &&
          session[:two_factor_authentication_challenge].present?
      end

      def verify_two_factor!(resource)
        credential_from_params = WebAuthn::Credential.from_get(JSON.parse(credential_param))
        stored_credential = resource&.webauthn_credentials&.find_by(external_id: credential_from_params.id)

        return fail!(:webauthn_credential_not_found) if stored_credential.blank?
        if user_handle_mismatch?(credential_from_params, resource)
          return fail!(:webauthn_credential_verification_failed)
        end

        verify_credential(credential_from_params, stored_credential)
      rescue WebAuthn::Error
        fail!(:webauthn_credential_verification_failed)
      ensure
        session.delete(:two_factor_authentication_challenge)
      end

      private

      def credential_param
        params[:public_key_credential]
      end

      def verify_credential(credential_from_params, stored_credential)
        credential_from_params.verify(
          session[:two_factor_authentication_challenge],
          public_key: stored_credential.public_key,
          sign_count: stored_credential.sign_count
        )

        stored_credential.update!(sign_count: credential_from_params.sign_count)
      end

      def user_handle_mismatch?(credential_from_params, resource)
        credential_from_params.user_handle.present? &&
          credential_from_params.user_handle != resource.webauthn_id
      end
    end
  end
end

Warden::Strategies.add(:webauthn_two_factor_authenticatable, Devise::Strategies::WebauthnTwoFactorAuthenticatable)
