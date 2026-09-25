# frozen_string_literal: true

module Devise
  class SecondFactorWebauthnCredentialsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PublicKeyCredentialParam
    include Devise::Webauthn::CredentialResponses

    before_action :authenticate_scope!

    def new; end

    def create
      security_key_from_params = WebAuthn::Credential.from_create(public_key_credential_param)

      if verify_and_save_security_key(security_key_from_params)
        respond_with_notice :security_key_created, location: after_create_path, status: :created
      else
        respond_with_alert :webauthn_credential_verification_failed, location: after_create_path
      end
    rescue WebAuthn::Error
      respond_with_alert :webauthn_credential_verification_failed, location: after_create_path
    ensure
      challenge_store.consume(:registration, public_key_credential_param)
    end

    def update
      if resource.second_factor_webauthn_credentials.find(params[:id]).update(authentication_factor: 0)
        respond_with_notice :security_key_promoted, location: after_update_path, status: :no_content
      else
        respond_with_alert :security_key_promotion_failed, location: after_update_path
      end
    end

    def destroy
      if resource.second_factor_webauthn_credentials.destroy(params[:id])
        respond_with_notice :security_key_deleted, location: after_destroy_path, status: :no_content
      else
        respond_with_alert :security_key_deletion_failed, location: after_destroy_path
      end
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end

    def verify_and_save_security_key(security_key_from_params)
      security_key_from_params.verify(
        challenge_store.consume(:registration, public_key_credential_param)
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
  end
end
