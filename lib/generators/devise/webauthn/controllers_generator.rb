# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class ControllersGenerator < Rails::Generators::Base
      CONTROLLERS = %w[
        passkeys
        second_factor_webauthn_credentials
        two_factor_authentications
      ].freeze

      desc "Create inherited Devise::Webauthn controllers in your app/controllers folder."

      source_root File.expand_path("templates/controllers", __dir__)
      argument :scope, required: true,
                       desc: "The scope to create controllers in, e.g. users, admins"
      class_option :controllers, aliases: "-c", type: :array,
                                 desc: "Select specific controllers to generate (#{CONTROLLERS.join(', ')})"

      def create_controllers
        @scope_prefix = scope.blank? ? "" : "#{scope.camelize}::"
        controllers = options[:controllers] || CONTROLLERS
        controllers.each do |name|
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
