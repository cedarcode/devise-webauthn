# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    module JavascriptSetup
      WEBAUTHN_IMPORTMAP_PIN = "@github/webauthn-json/browser-ponyfill"

      def setup_javascript_dependencies
        say "Setting up JavaScript dependencies for WebAuthn..."

        setup_webauthn_dependency
      end

      private

      def setup_webauthn_dependency
        case detected_package_manager
        when :importmaps
          add_webauthn_to_importmap
        when :yarn
          add_webauthn_with_yarn
        when :npm, :pnpm, :bun
          add_webauthn_with_npm
        else
          say "Warning: Could not detect package manager for WebAuthn dependency", :yellow
          say "Please install #{WEBAUTHN_IMPORTMAP_PIN} manually with your package manager"
        end
      end

      def add_webauthn_to_importmap
        say "Adding #{WEBAUTHN_IMPORTMAP_PIN} to importmap..."

        run "bin/importmap pin #{WEBAUTHN_IMPORTMAP_PIN} --no-integrity"
      rescue StandardError => e
        say "Error adding to importmap: #{e.message}", :red
        say "Please add this line to config/importmap.rb manually:", :yellow
        say WEBAUTHN_IMPORTMAP_PIN
      end

      def add_webauthn_with_yarn
        say "Installing #{WEBAUTHN_IMPORTMAP_PIN} with Yarn..."
        run "yarn add #{WEBAUTHN_IMPORTMAP_PIN}"
      rescue StandardError => e
        say "Error installing with Yarn: #{e.message}", :red
        say "Please install #{WEBAUTHN_IMPORTMAP_PIN} manually with Yarn"
      end

      def add_webauthn_with_npm
        say "Installing #{WEBAUTHN_IMPORTMAP_PIN} with npm..."
        run "npm install #{WEBAUTHN_IMPORTMAP_PIN}"
      rescue StandardError => e
        say "Error installing with npm: #{e.message}", :red
        say "Please install #{WEBAUTHN_IMPORTMAP_PIN} manually with npm"
      end

      def detected_package_manager
        return :yarn if File.exist?("yarn.lock")
        return :npm if File.exist?("package-lock.json")
        return :pnpm if File.exist?("pnpm-lock.yaml")
        return :bun if File.exist?("bun.lockb")
        return :importmaps if rails_has_gem?("importmap-rails")

        :none
      end

      def rails_has_gem?(gem_name)
        return false unless File.exist?("Gemfile.lock")

        File.read("Gemfile.lock").include?(gem_name)
      end
    end
  end
end
