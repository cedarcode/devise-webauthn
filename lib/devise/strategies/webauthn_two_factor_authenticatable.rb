# frozen_string_literal: true

module Devise
  module Strategies
    class WebauthnTwoFactorAuthenticatable < Devise::Strategies::Base
      include Devise::Webauthn::ChallengeStoreAccess
      include Devise::Webauthn::PublicKeyCredentialParam
      include Devise::Webauthn::PendingTwoFactorSignIn

      def valid?
        public_key_credential_param.present? &&
          pending_two_factor_sign_in(scope).present? &&
          challenge_store.pending?(:two_factor_authentication, public_key_credential_param)
      end

      def store?
        super && mapping.to.skip_session_storage.exclude?(:params_auth)
      end

      # rubocop:disable Metrics/AbcSize
      def authenticate!
        challenge = challenge_store.consume(:two_factor_authentication, public_key_credential_param)
        credential_from_params = WebAuthn::Credential.from_get(public_key_credential_param)
        pending_sign_in = pending_two_factor_sign_in(scope)
        resource = resource_class.find_by(id: pending_sign_in["id"])
        stored_credential = resource&.webauthn_credentials&.find_by(external_id: credential_from_params.id)

        return fail!(:webauthn_credential_not_found) if stored_credential.blank?
        if user_handle_mismatch?(credential_from_params, resource)
          return fail!(:webauthn_credential_verification_failed)
        end

        verify_credential(credential_from_params, stored_credential, challenge)

        resource.remember_me = pending_sign_in["remember_me"] if resource.respond_to?(:remember_me=)
        success!(resource)

        clear_pending_two_factor_sign_in
      rescue WebAuthn::Error
        fail!(:webauthn_credential_verification_failed)
      end
      # rubocop:enable Metrics/AbcSize

      private

      def verify_credential(credential_from_params, stored_credential, challenge)
        credential_from_params.verify(
          challenge,
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
