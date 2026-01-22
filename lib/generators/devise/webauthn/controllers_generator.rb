# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class ControllersGenerator < Rails::Generators::Base
      CONTROLLERS = %w[
        passkeys
        second_factor_webauthn_credentials
        two_factor_authentications
        passkey_authentication_options
        passkey_registration_options
        security_key_authentication_options
        security_key_registration_options
      ].freeze

      desc "Create inherited Devise::Webauthn controllers in your app/controllers folder."

      source_root File.expand_path("templates/controllers", __dir__)
      argument :scope, required: true,
                       desc: "The scope to create controllers in, e.g. users, admins"

      def create_controllers
        @scope_prefix = scope.blank? ? "" : "#{scope.camelize}::"
        CONTROLLERS.each do |name|
          template "#{name}_controller.rb",
                   "app/controllers/#{scope}/#{name}_controller.rb"
        end
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
