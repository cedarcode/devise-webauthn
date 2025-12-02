# frozen_string_literal: true

module Devise
  module Strategies
    class WebauthnTwoFactorAuthenticatable < Devise::Strategies::Base
      def valid?
        credential_param.present? && session[:two_factor_authentication_challenge].present?
      end

      def authenticate!
        credential_from_params = WebAuthn::Credential.from_get(JSON.parse(credential_param))
        stored_credential = WebauthnCredential.find_by(external_id: credential_from_params.id)

        return fail!(:webauthn_credential_not_found) if stored_credential.blank?

        verify_credential(credential_from_params, stored_credential)

        resource = stored_credential.public_send(resource_name)
        success!(resource)

        session.delete(:current_authentication_resource_id)
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

      def resource_name
        mapping.to.name.underscore
      end
    end
  end
end

Warden::Strategies.add(:webauthn_two_factor_authenticatable, Devise::Strategies::WebauthnTwoFactorAuthenticatable)
