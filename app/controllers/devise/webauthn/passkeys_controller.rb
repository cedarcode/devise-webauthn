# frozen_string_literal: true

module Devise
  module Webauthn
    class PasskeysController < DeviseController
      before_action :authenticate_user!

      def create
        passkey_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:passkey_public_key]))

        if verify_and_save_passkey(passkey_from_params)
          set_flash_message! :notice, :passkey_created, scope: :"devise.webauthn"
        else
          set_flash_message! :alert, :passkey_verification_failed, scope: :"devise.failure"
        end
        redirect_back fallback_location:
      rescue WebAuthn::Error
        set_flash_message! :alert, :passkey_verification_failed, scope: :"devise.failure"
        redirect_back fallback_location:
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
