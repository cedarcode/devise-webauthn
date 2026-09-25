# frozen_string_literal: true

module Devise
  class PasskeysController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PublicKeyCredentialParam
    include Devise::Webauthn::CredentialResponses

    before_action :authenticate_scope!

    def new; end

    def create
      passkey_from_params = WebAuthn::Credential.from_create(public_key_credential_param)

      if verify_and_save_passkey(passkey_from_params)
        respond_with_notice :passkey_created, location: after_update_path, status: :created
      else
        respond_with_alert :passkey_verification_failed, location: after_update_path
      end
    rescue WebAuthn::Error
      respond_with_alert :passkey_verification_failed, location: after_update_path
    ensure
      challenge_store.consume(:registration, public_key_credential_param)
    end

    def destroy
      if resource.passkeys.destroy(params[:id])
        respond_with_notice :passkey_deleted, location: after_update_path, status: :no_content
      else
        respond_with_alert :passkey_deletion_failed, location: after_update_path
      end
    end

    private

    def authenticate_scope!
      send(:"authenticate_#{resource_name}!", force: true)
      self.resource = send(:"current_#{resource_name}")
    end

    def verify_and_save_passkey(passkey_from_params)
      passkey_from_params.verify(
        challenge_store.consume(:registration, public_key_credential_param),
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
  end
end
