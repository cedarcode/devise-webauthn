# frozen_string_literal: true

module Devise
  class TwoFactorAuthenticationsController < DeviseController
    prepend_before_action :require_no_authentication
    append_before_action :ensure_sign_in_initiated
    append_before_action :set_resource

    def new
      @get_options = WebAuthn::Credential.options_for_get(
        allow: @resource.webauthn_credentials.pluck(:external_id),
        user_verification: "discouraged"
      )
      session[:two_factor_authentication_challenge] = @get_options.challenge
    end

    private

    def ensure_sign_in_initiated
      return if session[:current_authentication_resource_id].present?

      set_flash_message! :alert, :sign_in_not_initiated, scope: :"devise.failure"
      redirect_to new_session_path(resource_name)
    end

    def set_resource
      @resource = resource_class.find(session[:current_authentication_resource_id])
    end
  end
end
