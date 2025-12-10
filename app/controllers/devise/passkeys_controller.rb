# frozen_string_literal: true

module Devise
  class PasskeysController < DeviseController
    before_action :authenticate_scope!, only: %i[new create destroy options_for_create]

    def new; end

    def create
      passkey_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:public_key_credential]))

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

    def destroy
      resource.passkeys.destroy(params[:id])
      redirect_to after_update_path
    end

    def options_for_get
      passkey_authentication_options =
        WebAuthn::Credential.options_for_get(
          user_verification: "required"
        )

      # Store challenge in session for later verification
      session[:authentication_challenge] = passkey_authentication_options.challenge

      render json: passkey_authentication_options
    end

    def options_for_create
      create_passkey_options =
        WebAuthn::Credential.options_for_create(
          user: {
            id: resource.webauthn_id,
            name: resource_human_palatable_identifier
          },
          exclude: resource.passkeys.pluck(:external_id),
          authenticator_selection: {
            resident_key: "required",
            user_verification: "required"
          }
        )

      # Store challenge in session for later verification
      session[:webauthn_challenge] = create_passkey_options.challenge

      render json: create_passkey_options
    end

    private

    def authenticate_scope!
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
      new_passkey_path(resource_name)
    end

    def resource_human_palatable_identifier
      authentication_keys = resource.class.authentication_keys
      authentication_keys = authentication_keys.keys if authentication_keys.is_a?(Hash)

      authentication_keys.filter_map { |authentication_key| resource.public_send(authentication_key) }.first
    end
  end
end
