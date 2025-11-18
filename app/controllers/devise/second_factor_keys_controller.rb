# frozen_string_literal: true

module Devise
  class SecondFactorKeysController < DeviseController
    before_action :authenticate_scope!

    def new
      @options = WebAuthn::Credential.options_for_create(
        user: {
          id: resource.webauthn_id,
          name: resource.email
        },
        exclude: resource.webauthn_credentials.pluck(:external_id),
        authenticator_selection: {
          resident_key: "discouraged",
          user_verification: "discouraged"
        }
      )

      # Store challenge in session for later verification
      session[:webauthn_challenge] = @options.challenge
    end

    def create
      security_key_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:public_key_credential]))

      if verify_and_save_security_key(security_key_from_params)
        set_flash_message! :notice, :security_key_created
      else
        set_flash_message! :alert, :security_key_verification_failed, scope: :"devise.failure"
      end
      redirect_to after_update_path
    rescue WebAuthn::Error
      set_flash_message! :alert, :security_key_verification_failed, scope: :"devise.failure"
      redirect_to after_update_path
    ensure
      session.delete(:webauthn_challenge)
    end

    def destroy
      resource.second_factor_webauthn_credentials.destroy(params[:id])
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
    # this method in your own SecondFactorKeysController.
    def after_update_path
      new_second_factor_key_path(resource_name)
    end
  end
end
