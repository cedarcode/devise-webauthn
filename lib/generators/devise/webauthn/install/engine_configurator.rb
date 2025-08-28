# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    module EngineConfigurator
      def mount_passkeys_engine
        say "Adding passkeys engine mount...", :green
        routes_file = File.join(destination_root, "config/routes.rb")

        unless File.exist?(routes_file)
          say "Warning: config/routes.rb not found. Please add engine mount manually.", :yellow
          return
        end

        routes_content = File.read(routes_file)

        if routes_content.include?("mount Devise::Webauthn::Engine")
          say "Devise::Webauthn engine already mounted in config/routes.rb", :yellow
          return
        end

        inject_into_file routes_file, before: /^end\s*$/ do
          <<~RUBY.indent(2)
            mount Devise::Webauthn::Engine, at: "/devise-webauthn"
          RUBY
        end

        say "✓ Mounted Devise::Webauthn engine at /devise-webauthn", :green
      end
    end
  end
end
