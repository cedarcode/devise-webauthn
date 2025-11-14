# frozen_string_literal: true

Warden::Manager.after_authentication do |resource, auth, opts|
  if resource.second_factor_enabled? && !auth.env["rack.session"][:second_factor_authenticated]
    auth.logout
    auth.env["rack.session"][:current_authentication_resource_id] = resource.id
    throw(:warden, scope: opts[:scope], resource: resource, message: :two_factor_required)
  end
end
