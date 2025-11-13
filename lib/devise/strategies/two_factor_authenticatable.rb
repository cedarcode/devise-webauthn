# frozen_string_literal: true

module Devise
  module Strategies
    class TwoFactorAuthenticatable < Warden::Strategies::Base
      def valid?
        passkey_param.present? && session[:'2fa_authentication_challenge'].present?
      end

      def authenticate!
        passkey_from_params = WebAuthn::Credential.from_get(JSON.parse(passkey_param))
        stored_passkey = WebauthnCredential.find_by(external_id: passkey_from_params.id)

        return fail!(:passkey_not_found) if stored_passkey.blank?

        verify_credential(passkey_from_params, stored_passkey)

        session[:second_factor_authenticated] = true

        success!(stored_passkey.user)
      rescue WebAuthn::Error
        fail!(:'2fa_authentication_challenge')
      ensure
        session.delete(:'2fa_authentication_challenge')
      end

      private

      def passkey_param
        params[:public_key_credential]
      end

      def verify_credential(passkey_from_params, stored_passkey)
        passkey_from_params.verify(
          session[:'2fa_authentication_challenge'],
          public_key: stored_passkey.public_key,
          sign_count: stored_passkey.sign_count,
        )

        stored_passkey.update!(sign_count: passkey_from_params.sign_count)
      end
    end
  end
end

Warden::Strategies.add(:two_factor_authenticatable, Devise::Strategies::TwoFactorAuthenticatable)
