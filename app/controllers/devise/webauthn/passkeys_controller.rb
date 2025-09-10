# frozen_string_literal: true

module Devise
  module Webauthn
    class PasskeysController < DeviseController
      before_action :authenticate_resource!

      def new; end

      def create
        passkey_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:passkey_public_key]))

        if verify_and_save_passkey(passkey_from_params)
          set_flash_message! :notice, :passkey_created
        else
          set_flash_message! :alert, :passkey_verification_failed, scope: :"devise.failure"
        end
        redirect_to after_update_path
      rescue WebAuthn::Error
        set_flash_message! :alert, :passkey_verification_failed, scope: :"devise.failure"
        redirect_to after_update_path
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

      # The default url to be used after creating a passkey. You can overwrite
      # this method in your own PasskeysController.
      def after_update_path
        public_send("new_#{resource_name}_passkey_path")
      end
    end
  end
end
