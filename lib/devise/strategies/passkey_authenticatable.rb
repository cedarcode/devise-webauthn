# frozen_string_literal: true

module Devise
  module Strategies
    class PasskeyAuthenticatable < Warden::Strategies::Base
      def valid?
        passkey_param.present? && session[:authentication_challenge].present?
      end

      def authenticate!
        webauthn_passkey = parse_webauthn_credential
        passkey = find_passkey(webauthn_passkey.id)

        return fail!(I18n.t("devise.webauthn.errors.passkey_not_found")) if passkey.blank?

        verify_and_authenticate(webauthn_passkey, passkey)
      rescue WebAuthn::Error
        fail!(I18n.t("devise.webauthn.errors.verification_failed"))
      ensure
        session.delete(:authentication_challenge)
      end

      private

      def passkey_param
        params.dig(:user, :passkey_public_key)
      end

      def parse_webauthn_credential
        WebAuthn::Credential.from_get(JSON.parse(passkey_param))
      end

      def find_passkey(external_id)
        Passkey.find_by(external_id:)
      end

      def verify_and_authenticate(webauthn_passkey, passkey)
        webauthn_passkey.verify(
          session[:authentication_challenge],
          public_key: passkey.public_key,
          sign_count: passkey.sign_count,
          user_verification: true
        )

        passkey.update!(sign_count: webauthn_passkey.sign_count)
        success!(passkey.user)
      end
    end
  end
end
