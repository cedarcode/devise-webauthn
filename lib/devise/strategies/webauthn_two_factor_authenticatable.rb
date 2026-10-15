# frozen_string_literal: true

module Devise
  module Strategies
    class WebauthnTwoFactorAuthenticatable < Devise::Strategies::Base
      include Devise::Webauthn::ChallengeStoreAccess
      include Devise::Webauthn::PublicKeyCredentialParam
      include Devise::Webauthn::PendingTwoFactorSignIn

      def valid?
        public_key_credential_param.present? &&
          two_factor_sign_in_attempt_for(scope).present? &&
          challenge_store.pending?(:two_factor_authentication)
      end

      def store?
        super && mapping.to.skip_session_storage.exclude?(:params_auth)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      def authenticate!
        expected_challenge = challenge_store.consume(:two_factor_authentication)
        credential_from_params = WebAuthn::Credential.from_get(public_key_credential_param)
        sign_in_attempt = two_factor_sign_in_attempt_for(scope)
        resource = resource_class.find_by(id: sign_in_attempt["id"])
        stored_credential = resource&.webauthn_credentials&.find_by(external_id: credential_from_params.id)

        return fail!(:webauthn_credential_not_found) if stored_credential.blank?
        if user_handle_mismatch?(credential_from_params, resource)
          return fail!(:webauthn_credential_verification_failed)
        end

        verify_credential(credential_from_params, stored_credential, expected_challenge)
        return fail!(:sign_in_not_initiated) unless consume_two_factor_sign_in_attempt(sign_in_attempt)

        resource.remember_me = sign_in_attempt["remember_me"] if resource.respond_to?(:remember_me=)
        success!(resource)
      rescue WebAuthn::Error
        fail!(:webauthn_credential_verification_failed)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

      private

      def verify_credential(credential_from_params, stored_credential, expected_challenge)
        credential_from_params.verify(
          expected_challenge,
          public_key: stored_credential.public_key,
          sign_count: stored_credential.sign_count
        )

        stored_credential.update!(sign_count: credential_from_params.sign_count)
      end

      def user_handle_mismatch?(credential_from_params, resource)
        credential_from_params.user_handle.present? &&
          credential_from_params.user_handle != resource.webauthn_id
      end

      def resource_class
        mapping.to
      end
    end
  end
end

Warden::Strategies.add(:webauthn_two_factor_authenticatable, Devise::Strategies::WebauthnTwoFactorAuthenticatable)
