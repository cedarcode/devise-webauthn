# frozen_string_literal: true

module Devise
  module Strategies
    class PasskeyAuthenticatable < Warden::Strategies::Base
      def valid?
        passkey_param.present? && session[:authentication_challenge].present?
      end

      def authenticate!
        passkey_from_params = WebAuthn::Credential.from_get(JSON.parse(passkey_param))
        stored_passkey = WebauthnCredential.find_by(external_id: passkey_from_params.id)

        return fail!(:passkey_not_found) if stored_passkey.blank?

        verify_passkeys(passkey_from_params, stored_passkey)

        success!(stored_passkey.user)
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
    end
  end
end
