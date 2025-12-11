# frozen_string_literal: true

module Devise
  class SecondFactorWebauthnCredentialsController < DeviseController
    before_action :authenticate_scope!

    def new; end

    def create
      security_key_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:public_key_credential]))

      if verify_and_save_security_key(security_key_from_params)
        set_flash_message! :notice, :security_key_created
      else
        set_flash_message! :alert, :webauthn_credential_verification_failed, scope: :"devise.failure"
      end
      redirect_to after_update_path
    rescue WebAuthn::Error
      set_flash_message! :alert, :webauthn_credential_verification_failed, scope: :"devise.failure"
      redirect_to after_update_path
    ensure
      session.delete(:webauthn_challenge)
    end

    def destroy
      if resource.second_factor_webauthn_credentials.destroy(params[:id])
        set_flash_message! :notice, :security_key_deleted
      else
        set_flash_message! :alert, :webauthn_credential_deletion_failed, scope: :"devise.failure"
      end

      redirect_to after_update_path
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end

    def verify_and_save_security_key(security_key_from_params)
      security_key_from_params.verify(
        session[:webauthn_challenge]
      )

      resource.second_factor_webauthn_credentials.create(
        external_id: security_key_from_params.id,
        name: params[:name],
        public_key: security_key_from_params.public_key,
        sign_count: security_key_from_params.sign_count
      )
    end

    # The default url to be used after creating a second factor key. You can overwrite
    # this method in your own SecondFactorWebauthnCredentialsController.
    def after_update_path
      new_second_factor_webauthn_credential_path(resource_name)
    end
  end
end
