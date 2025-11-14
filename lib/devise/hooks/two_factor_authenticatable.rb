# frozen_string_literal: true

require "devise/two_factor_required_failure_app"

Warden::Manager.after_authentication do |resource, auth, opts|
  if resource.second_factor_enabled? && !auth.env["rack.session"][:second_factor_authenticated]
    auth.env["rack.session"][:current_authentication_resource_id] = resource.id
    auth.logout
    throw(:warden, scope: opts[:scope], resource: resource, message: :two_factor_required)
  end
end

Devise.setup do |config|
  config.warden do |manager|
    manager.failure_app = TwoFactorRequiredFailureApp
  end
end
