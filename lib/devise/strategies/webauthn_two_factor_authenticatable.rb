# frozen_string_literal: true

module Devise
  module Strategies
    class WebauthnTwoFactorAuthenticatable < Warden::Strategies::Base
      def valid?
        credential_param.present? && session[:two_factor_authentication_challenge].present?
      end

      def authenticate!
        credential_from_params = WebAuthn::Credential.from_get(JSON.parse(credential_param))
        stored_credential = WebauthnCredential.find_by(external_id: credential_from_params.id)

        return fail!(:security_key_not_found) if stored_credential.blank?

        verify_credential(credential_from_params, stored_credential)

        success!(stored_credential.user)

        session.delete(:current_authentication_resource_id)
      rescue WebAuthn::Error
        fail!(:security_key_verification_failed)
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
    end
  end
end

Warden::Strategies.add(:webauthn_two_factor_authenticatable, Devise::Strategies::WebauthnTwoFactorAuthenticatable)
