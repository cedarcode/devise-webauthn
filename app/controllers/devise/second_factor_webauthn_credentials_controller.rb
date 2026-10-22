# frozen_string_literal: true

module Devise
  class SecondFactorWebauthnCredentialsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PublicKeyCredentialParam

    before_action :authenticate_scope!

    def new; end

    def create
      security_key = verify_and_save_security_key(public_key_credential_param)

      if security_key.persisted?
        set_flash_message! :notice, :security_key_created
      else
        set_flash_message! :alert, :webauthn_credential_verification_failed, scope: :"devise.failure"
      end
      if security_key.persisted? && !is_navigational_format?
        head :created
      else
        # The responder calls the location lambda only when the security key has no errors.
        respond_with_navigational(security_key, location: -> { after_create_path }) { redirect_to after_create_path }
      end
    ensure
      challenge_store.consume(:registration)
    end

    def update
      security_key = resource.second_factor_webauthn_credentials.find(params[:id])

      if security_key.update(authentication_factor: 0)
        set_flash_message! :notice, :security_key_promoted
      else
        set_flash_message! :alert, :security_key_promotion_failed, scope: :"devise.failure"
      end
      respond_with_navigational(security_key) { redirect_to after_update_path }
    end

    def destroy
      security_key = resource.second_factor_webauthn_credentials.find(params[:id])

      if security_key.destroy
        set_flash_message! :notice, :security_key_deleted
      else
        set_flash_message! :alert, :security_key_deletion_failed, scope: :"devise.failure"
      end
      respond_with_navigational(security_key) { redirect_to after_destroy_path }
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end

    def verify_and_save_security_key(public_key_credential)
      return security_key_with_verification_error if public_key_credential.nil?

      security_key_from_params = WebAuthn::Credential.from_create(public_key_credential)
      security_key_from_params.verify(
        challenge_store.consume(:registration)
      )

      resource.second_factor_webauthn_credentials.create(
        external_id: security_key_from_params.id,
        name: params[:name],
        public_key: security_key_from_params.public_key,
        sign_count: security_key_from_params.sign_count
      )
    rescue WebAuthn::Error
      security_key_with_verification_error
    end

    def security_key_with_verification_error
      security_key = WebauthnCredential.new
      security_key.errors.add(:base, find_message(:webauthn_credential_verification_failed, scope: :"devise.failure"))
      security_key
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
