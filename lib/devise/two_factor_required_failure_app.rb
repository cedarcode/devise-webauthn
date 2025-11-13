# frozen_string_literal: true

class TwoFactorRequiredFailureApp < Devise::FailureApp
  def redirect_url
    if warden_message == :two_factor_required
      # new_second_factor_authentication_url(scope: scope)
      send(:"new_#{scope}_second_factor_authentication_path")
    else
      super
    end
  end
end
