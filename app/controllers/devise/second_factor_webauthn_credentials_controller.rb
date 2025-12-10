# frozen_string_literal: true

module Devise
  class SecondFactorWebauthnCredentialsController < DeviseController
    before_action :authenticate_scope!, only: %i[new create destroy options_for_create]
    before_action :set_resource, only: :options_for_get

    def new; end

    def create
      security_key_from_params = WebAuthn::Credential.from_create(JSON.parse(params[:public_key_credential]))

      if verify_and_save_security_key(security_key_from_params)
        set_flash_message! :notice, :security_key_created
      else
        set_flash_message! :alert, :webauthn_credential_verification_failed, scope: :"devise.failure"
      end
      redirect_to after_create_path
    rescue WebAuthn::Error
      set_flash_message! :alert, :webauthn_credential_verification_failed, scope: :"devise.failure"
      redirect_to after_create_path
    ensure
      session.delete(:webauthn_challenge)
    end

    def update
      if resource.second_factor_webauthn_credentials.find(params[:id]).update(authentication_factor: 0)
        set_flash_message! :notice, :security_key_promoted
      else
        set_flash_message! :alert, :security_key_promotion_failed, scope: :"devise.failure"
      end

      redirect_to after_update_path
    end

    def destroy
      if resource.second_factor_webauthn_credentials.destroy(params[:id])
        set_flash_message! :notice, :security_key_deleted
      else
        set_flash_message! :alert, :security_key_deletion_failed, scope: :"devise.failure"
      end

      redirect_to after_destroy_path
    end

    def options_for_get
      security_key_authentication_options =
        WebAuthn::Credential.options_for_get(
          allow: @resource.webauthn_credentials.pluck(:external_id),
          user_verification: "discouraged"
        )

      # Store challenge in session for later verification
      session[:two_factor_authentication_challenge] = security_key_authentication_options.challenge

      render json: security_key_authentication_options
    end

    def options_for_create
      create_security_key_options =
        WebAuthn::Credential.options_for_create(
          user: {
            id: resource.webauthn_id,
            name: resource_human_palatable_identifier
          },
          exclude: resource.webauthn_credentials.pluck(:external_id),
          authenticator_selection: {
            resident_key: "discouraged",
            user_verification: "discouraged"
          }
        )

      # Store challenge in session for later verification
      session[:webauthn_challenge] = create_security_key_options.challenge

      render json: create_security_key_options
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
    def after_create_path
      new_second_factor_webauthn_credential_path(resource_name)
    end

    # The default url to be used after creating a second factor key. You can overwrite
    # this method in your own SecondFactorWebauthnCredentialsController.
    def after_update_path
      request.referer || new_second_factor_webauthn_credential_path(resource_name)
    end

    # The default url to be used after deleting a second factor key. You can overwrite
    # this method in your own SecondFactorWebauthnCredentialsController.
    def after_destroy_path
      new_second_factor_webauthn_credential_path(resource_name)
    end

    def resource_human_palatable_identifier
      authentication_keys = resource.class.authentication_keys
      authentication_keys = authentication_keys.keys if authentication_keys.is_a?(Hash)

      authentication_keys.filter_map { |authentication_key| resource.public_send(authentication_key) }.first
    end

    def set_resource
      @resource = resource_class.find(session[:current_authentication_resource_id])
    end
  end
end
