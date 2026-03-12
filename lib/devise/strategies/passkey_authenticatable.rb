# frozen_string_literal: true

module Devise
  module Strategies
    class PasskeyAuthenticatable < Devise::Strategies::Base
      def valid?
        passkey_param.present? && session[:authentication_challenge].present?
      end

      def authenticate!
        passkey_from_params = WebAuthn::Credential.from_get(JSON.parse(passkey_param))
        resource = resource_class.find_by(webauthn_id: passkey_from_params.user_handle)
        stored_passkey = resource&.passkeys&.find_by(external_id: passkey_from_params.id)

        return fail!(:passkey_not_found) if stored_passkey.blank?

        verify_passkeys(passkey_from_params, stored_passkey)

        success!(resource)
      rescue WebAuthn::Error
        fail!(:passkey_verification_failed)
      ensure
        session.delete(:authentication_challenge)
      end

      private

      def passkey_param
        params[:public_key_credential]
      end

      def verify_passkeys(passkey_from_params, stored_passkey)
        passkey_from_params.verify(
          session[:authentication_challenge],
          public_key: stored_passkey.public_key,
          sign_count: stored_passkey.sign_count,
          user_verification: true
        )

        stored_passkey.update!(sign_count: passkey_from_params.sign_count)
      end

      def resource_class
        mapping.to
      end
    end
  end
end

Warden::Strategies.add(:passkey_authenticatable, Devise::Strategies::PasskeyAuthenticatable)
