# frozen_string_literal: true

module Devise
  module Webauthn
    class PasskeysController < DeviseController
      before_action :authenticate_resource!

      def new
        @create_passkey_options = WebAuthn::Credential.options_for_create(
          user: {
            id: resource.webauthn_id,
            name: resource.email
          },
          exclude: resource.passkeys.pluck(:external_id),
          authenticator_selection: {
            resident_key: "required",
            user_verification: "required"
          }
        )

        # Store challenge in session for later verification
        session[:webauthn_challenge] = @create_passkey_options.challenge
      end

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

      def authenticate_resource!
        send(:"authenticate_#{resource_name}!", force: true)
        self.resource = send(:"current_#{resource_name}")
      end

      def verify_and_save_passkey(passkey_from_params)
        passkey_from_params.verify(
          session[:webauthn_challenge],
          user_verification: true
        )

        resource.passkeys.create(
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
