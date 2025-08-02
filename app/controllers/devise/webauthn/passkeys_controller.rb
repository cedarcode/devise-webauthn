# frozen_string_literal: true

module Devise
  module Webauthn
    class PasskeysController < ApplicationController
      before_action :authenticate_user!

      def create
        webauthn_passkey = parse_passkey_from_params

        if verify_and_save_passkey(webauthn_passkey)
          redirect_back fallback_location: root_path, notice: I18n.t("devise.webauthn.passkey.created")
        else
          redirect_back fallback_location: root_path, alert: I18n.t("devise.webauthn.passkey.creation_failed")
        end
      rescue WebAuthn::Error
        redirect_back fallback_location: root_path, alert: I18n.t("devise.webauthn.errors.verification_failed")
      ensure
        session.delete(:webauthn_challenge)
      end

      private

      def parse_passkey_from_params
        WebAuthn::Credential.from_create(JSON.parse(params[:passkey_public_key]))
      end

      def verify_and_save_passkey(webauthn_passkey)
        webauthn_passkey.verify(
          session[:webauthn_challenge],
          user_verification: true
        )

        passkey = build_passkey(webauthn_passkey)
        passkey.save
      end

      def build_passkey(webauthn_passkey)
        current_user.passkeys.build(
          external_id: webauthn_passkey.id,
          name: params[:name],
          public_key: webauthn_passkey.public_key,
          sign_count: webauthn_passkey.sign_count
        )
      end
    end
  end
end
