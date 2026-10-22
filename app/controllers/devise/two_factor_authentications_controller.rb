# frozen_string_literal: true

module Devise
  class TwoFactorAuthenticationsController < DeviseController
    include Devise::Webauthn::PendingTwoFactorSignIn

    prepend_before_action :set_resource, only: :new
    prepend_before_action :ensure_sign_in_initiated
    prepend_before_action :require_no_authentication
    prepend_before_action :allow_params_authentication!, only: :create

    def new; end

    def create
      # Only the second factor, so a first-factor strategy cannot take the request.
      self.resource = warden.authenticate!(:webauthn_two_factor_authenticatable, auth_options)
      set_flash_message! :notice, :signed_in, scope: :"devise.sessions"
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    protected

    def auth_options
      { scope: resource_name, recall: "#{controller_path}#new", locale: I18n.locale }
    end

    private

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
