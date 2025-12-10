# frozen_string_literal: true

module Devise
  module Webauthn
    # Create url helpers to be used with resource/scope configuration. Acts as
    # proxies to the generated routes created by devise.
    # Resource param can be a string or symbol, a class, or an instance object.
    # Example using a :user resource:
    #
    #   new_passkey_path(:user)      => new_user_passkey_path
    #   passkeys_path(:user)         => user_passkeys_path
    #   passkey_path(:user)          => user_passkey_path
    #
    # Those helpers are included by default to ActionController::Base.
    #
    # In case you want to add such helpers to another class, you can do
    # that as long as this new class includes both url_helpers and
    # mounted_helpers. Example:
    #
    #     include Rails.application.routes.url_helpers
    #     include Rails.application.routes.mounted_helpers
    #
    module UrlHelpers
      {
        passkeys: [nil],
        passkey: [nil, :new],
        two_factor_authentication: [nil, :new],
        second_factor_webauthn_credentials: [nil],
        second_factor_webauthn_credential: [nil, :new]
      }.each do |route, actions|
        %i[path url].each do |path_or_url|
          actions.each do |action|
            action = action ? "#{action}_" : ""
            method = :"#{action}#{route}_#{path_or_url}"

            define_method method do |resource_or_scope, *args|
              scope = Devise::Mapping.find_scope!(resource_or_scope)
              router_name = Devise.mappings[scope].router_name
              context = router_name ? send(router_name) : _devise_route_context
              context.send("#{action}#{scope}_#{route}_#{path_or_url}", *args)
            end
          end
        end
      end
    end
  end
end
