# frozen_string_literal: true

module Devise
  class TwoFactorAuthenticationsController < DeviseController
    include Devise::Webauthn::ChallengeStoreAccess
    include Devise::Webauthn::PublicKeyCredentialParam
    include Devise::Webauthn::PendingTwoFactorSignIn

    prepend_before_action :set_resource, only: :new
    prepend_before_action :ensure_sign_in_initiated
    prepend_before_action :require_no_authentication

    def new; end

    def create
      self.resource = verify_second_factor!
      set_flash_message! :notice, :signed_in, scope: :"devise.sessions"
      # `event: :authentication` runs Warden's `after_authentication` hooks, as a sign-in through a strategy does.
      sign_in(resource_name, resource, event: :authentication, store: store_user_in_session?)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    protected

    def auth_options
      { scope: resource_name, recall: "#{controller_path}#new", locale: I18n.locale }
    end

    private

    def verify_second_factor!
      fail_second_factor! unless second_factor_answered?

      sign_in_attempt = two_factor_sign_in_attempt_for(resource_name)
      resource = resource_class.find_by(id: sign_in_attempt["id"])
      verify_credential!(resource)

      resource.remember_me = sign_in_attempt["remember_me"] if resource.respond_to?(:remember_me=)
      clear_two_factor_sign_in_attempt(resource_name)
      resource
    end

    def second_factor_answered?
      public_key_credential_param.present? && challenge_store.pending?(:two_factor_authentication)
    end

    # rubocop:disable Metrics/AbcSize
    def verify_credential!(resource)
      expected_challenge = challenge_store.consume(:two_factor_authentication)
      credential_from_params = WebAuthn::Credential.from_get(public_key_credential_param)
      stored_credential = resource&.webauthn_credentials&.find_by(external_id: credential_from_params.id)

      fail_second_factor!(:webauthn_credential_not_found) if stored_credential.blank?
      if user_handle_mismatch?(credential_from_params, resource)
        fail_second_factor!(:webauthn_credential_verification_failed)
      end

      credential_from_params.verify(
        expected_challenge,
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )
      stored_credential.update!(sign_count: credential_from_params.sign_count)
    rescue WebAuthn::Error
      fail_second_factor!(:webauthn_credential_verification_failed)
    end
    # rubocop:enable Metrics/AbcSize

    def fail_second_factor!(message = nil)
      throw :warden, auth_options.merge(message: message)
    end

    def user_handle_mismatch?(credential_from_params, resource)
      credential_from_params.user_handle.present? &&
        credential_from_params.user_handle != resource.webauthn_id
    end

    def store_user_in_session?
      two_factor_token_stored_in_session?(resource_name)
    end

    def ensure_sign_in_initiated
      return if two_factor_sign_in_attempt_for(resource_name).present?

      throw :warden, scope: resource_name, message: :sign_in_not_initiated unless is_navigational_format?

      set_flash_message! :alert, :sign_in_not_initiated, scope: :"devise.failure"
      redirect_to new_session_path(resource_name)
    end

    def set_resource
      @resource = resource_class.find(two_factor_sign_in_attempt_for(resource_name)["id"])
    end
  end
end
