# frozen_string_literal: true

module Devise
  module Strategies
    class WebauthnTwoFactorAuthenticatable < Devise::Strategies::Base
      def valid?
        credential_param.present? &&
          session[:current_authentication_resource_id].present? &&
          session[:two_factor_authentication_challenge].present?
      end

      # rubocop:disable Metrics/AbcSize
      def authenticate!
        credential_from_params = WebAuthn::Credential.from_get(JSON.parse(credential_param))
        resource = resource_class.find_by(id: session[:current_authentication_resource_id])
        stored_credential = resource&.webauthn_credentials&.find_by(external_id: credential_from_params.id)

        return fail!(:webauthn_credential_not_found) if stored_credential.blank?

        verify_credential(credential_from_params, stored_credential)

        resource.remember_me = session[:current_authentication_remember_me] if resource.respond_to?(:remember_me=)
        success!(resource)

        session.delete(:current_authentication_resource_id)
        session.delete(:current_authentication_remember_me)
      rescue WebAuthn::Error
        fail!(:webauthn_credential_verification_failed)
      ensure
        session.delete(:two_factor_authentication_challenge)
      end
      # rubocop:enable Metrics/AbcSize

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

      def resource_class
        mapping.to
      end
    end
  end
end

Warden::Strategies.add(:webauthn_two_factor_authenticatable, Devise::Strategies::WebauthnTwoFactorAuthenticatable)
