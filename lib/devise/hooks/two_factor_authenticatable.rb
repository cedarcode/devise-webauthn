# frozen_string_literal: true

require "devise/two_factor_required_failure_app"

Warden::Manager.after_set_user do |user, auth, opts|
  if user.second_factor_enabled?
    auth.env["rack.session"][:pre_2fa_user_id] = user.id
    auth.logout
    throw(:warden, scope: opts[:scope], resource: user, message: :two_factor_required)
  end
end

Devise.setup do |config|
  config.warden do |manager|
    manager.failure_app = TwoFactorRequiredFailureApp
  end
end
