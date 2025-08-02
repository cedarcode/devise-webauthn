# frozen_string_literal: true

module Devise
  module Webauthn
    class PasskeysController < ApplicationController
      before_action :authenticate_user!

      def create
        passkey_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:passkey_public_key]))

        if verify_and_save_passkey(passkey_from_params)
          redirect_back fallback_location:, notice: I18n.t("devise.webauthn.passkey_created")
        else
          redirect_back fallback_location:, alert: I18n.t("devise.webauthn.passkey_creation_failed")
        end
      rescue WebAuthn::Error
        redirect_back fallback_location:, alert: I18n.t("devise.failure.passkey_verification_failed")
      ensure
        session.delete(:webauthn_challenge)
      end

      private

      def verify_and_save_passkey(passkey_from_params)
        passkey_from_params.verify(
          session[:webauthn_challenge],
          user_verification: true
        )

        current_user.passkeys.create(
          external_id: passkey_from_params.id,
          name: params[:name],
          public_key: passkey_from_params.public_key,
          sign_count: passkey_from_params.sign_count
        )
      end

      def fallback_location = main_app.root_path
    end
  end
end
