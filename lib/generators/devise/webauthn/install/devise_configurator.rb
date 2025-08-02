# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    module DeviseConfigurator
      def setup_devise_integration
        say "Adding passkeys routes...", :green
        add_passkeys_routes
      end

      private

      def add_passkeys_routes
        routes_file = "config/routes.rb"

        unless File.exist?(routes_file)
          say "Warning: config/routes.rb not found. Please add passkeys routes manually.", :yellow
          return
        end

        routes_content = File.read(routes_file)

        if routes_content.include?("passkeys")
          say "Passkeys routes already exist in config/routes.rb", :yellow
          return
        end

        # Add the simple passkeys scope
        route_content = <<~RUBY

          # Devise::Webauthn passkeys routes
          scope module: "devise/webauthn" do
            resources :passkeys, only: %i[create]
          end
        RUBY

        inject_into_file routes_file, before: /^end\s*$/ do
          route_content
        end

        say "✓ Added passkeys routes to config/routes.rb", :green
      end
    end
  end
end
