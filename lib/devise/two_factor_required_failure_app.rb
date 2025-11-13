# frozen_string_literal: true

class TwoFactorRequiredFailureApp < Devise::FailureApp
  def redirect_url
    if warden_message == :two_factor_required
      # new_second_factor_authentication_url(scope: scope)
      # store_resource(scope, resource)
      session[:pre_2fa_user_id] = resource.id
      send(:"new_#{scope}_second_factor_authentication_path")
    else
      super
    end
  end

  private

  def resource
    warden_options[:resource]
  end
  #
  # def store_resource(resource_or_scope, resource)
  #   byebug
  #   session_key = stored_resource_key_for(resource_or_scope)
  #
  #   session[session_key] = resource if resource
  # end
end
