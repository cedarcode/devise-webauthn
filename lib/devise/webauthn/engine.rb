# frozen_string_literal: true

module Devise
  module Webauthn
    class Engine < ::Rails::Engine
      isolate_namespace Devise::Webauthn

      initializer "devise.webauthn.add_module" do
        Devise.add_module(
          :passkey_authenticatable,
          {
            model: "devise/models/passkey_authenticatable",
            strategy: true,
            route: { passkey_authentication: [] }
          }
        )

        Devise.register_two_factor_method(
          :webauthn,
          {
            model: "devise/models/webauthn_two_factor_authenticatable",
            strategy: :webauthn_two_factor_authenticatable,
            route: { webauthn: [] }
          }
        )
      end

      initializer "devise.webauthn.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Devise::Webauthn::CredentialsHelper
        end
      end

      initializer "devise.webauthn.url_helpers" do
        Devise.include_helpers(Devise::Webauthn)
      end

      initializer "devise.webauthn.assets" do
        if ::Rails.application.config.respond_to?(:assets)
          ::Rails.application.config.assets.precompile += %w[devise/webauthn.js]
        end
      end
    end
  end
end
