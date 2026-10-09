# frozen_string_literal: true

module Devise
  class PasskeysController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PublicKeyCredentialParam

    before_action :authenticate_scope!

    def new; end

    def create
      passkey = verify_and_save_passkey(public_key_credential_param)

      if passkey.persisted?
        set_flash_message! :notice, :passkey_created
      else
        set_flash_message! :alert, :passkey_verification_failed, scope: :"devise.failure"
      end
      respond_with_navigational(passkey, location: after_update_path) { redirect_to after_update_path }
    ensure
      challenge_store.consume(:registration)
    end

    def destroy
      passkey = resource.passkeys.find(params[:id])

      if passkey.destroy
        set_flash_message! :notice, :passkey_deleted
      else
        set_flash_message! :alert, :passkey_deletion_failed, scope: :"devise.failure"
      end
      respond_with_navigational(passkey, location: after_update_path) { redirect_to after_update_path }
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end

    def verify_and_save_passkey(public_key_credential)
      passkey_from_params = WebAuthn::Credential.from_create(public_key_credential)
      passkey_from_params.verify(
        challenge_store.consume(:registration),
        user_verification: true
      )

      resource.passkeys.create(
        external_id: passkey_from_params.id,
        name: params[:name],
        public_key: passkey_from_params.public_key,
        sign_count: passkey_from_params.sign_count
      )
    rescue WebAuthn::Error
      unverified_passkey
    end

    def unverified_passkey
      passkey = resource.passkeys.new
      passkey.errors.add(:base, find_message(:passkey_verification_failed, scope: :"devise.failure"))
      passkey
    end

    # The default url to be used after creating a passkey. You can overwrite
    # this method in your own PasskeysController.
    def after_update_path
      new_passkey_path(resource_name)
    end
  end
end
