# frozen_string_literal: true

module RedirectUrlWithTwoFactor
  def redirect_url
    if warden_message == :two_factor_required
      send(:"new_#{scope}_second_factor_authentication_path")
    else
      super
    end
  end
end

ActiveSupport.on_load(:devise_failure_app) do
  Devise::FailureApp.prepend(RedirectUrlWithTwoFactor)
end
