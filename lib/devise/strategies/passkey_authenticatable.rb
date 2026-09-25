# frozen_string_literal: true

module Devise
  module Strategies
    class PasskeyAuthenticatable < Devise::Strategies::Base
      include Devise::Webauthn::ChallengeStoreAccess
      include Devise::Webauthn::PublicKeyCredentialParam

      def valid?
        public_key_credential_param.present? &&
          challenge_store.pending?(:passkey_authentication, public_key_credential_param)
      end

      def store?
        super && mapping.to.skip_session_storage.exclude?(:params_auth)
      end

      def authenticate! # rubocop:disable Metrics/AbcSize
        challenge = challenge_store.consume(:passkey_authentication, public_key_credential_param)
        passkey_from_params = WebAuthn::Credential.from_get(public_key_credential_param)

        return fail!(:passkey_not_found) if passkey_from_params.user_handle.nil?

        resource = resource_class.find_by(webauthn_id: passkey_from_params.user_handle)
        stored_passkey = resource&.passkeys&.find_by(external_id: passkey_from_params.id)

        return fail!(:passkey_not_found) if stored_passkey.blank?

        verify_passkeys(passkey_from_params, stored_passkey, challenge)

        remember_me(resource)
        success!(resource)
      rescue WebAuthn::Error
        fail!(:passkey_verification_failed)
      end

      private

      def verify_passkeys(passkey_from_params, stored_passkey, challenge)
        passkey_from_params.verify(
          challenge,
          public_key: stored_passkey.public_key,
          sign_count: stored_passkey.sign_count,
          user_verification: true
        )

        stored_passkey.update!(sign_count: passkey_from_params.sign_count)
      end

      def remember_me(resource)
        resource.remember_me = remember_me? if resource.respond_to?(:remember_me=)
      end

      def remember_me?
        params_auth_hash.is_a?(Hash) && Devise::TRUE_VALUES.include?(params_auth_hash[:remember_me])
      end

      def params_auth_hash
        params[scope]
      end

      def resource_class
        mapping.to
      end
    end
  end
end

Warden::Strategies.add(:passkey_authenticatable, Devise::Strategies::PasskeyAuthenticatable)
