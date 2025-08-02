# frozen_string_literal: true

require "rails/generators"
require_relative "files_configurator"
require_relative "javascript_setup"
require_relative "devise_configurator"

module Devise
  module Webauthn
    class InstallGenerator < Rails::Generators::Base
      include FilesConfigurator
      include JavascriptSetup
      include DeviseConfigurator

      source_root File.expand_path("templates", __dir__)

      desc "Install Devise::Webauthn configuration into your application"

      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def install
        say "Installing DeviseWebauthn configuration...", :green

        setup_configuration_files
        setup_javascript_dependencies
        setup_devise_integration
        generate_models_and_migrations

        show_install_completion
      end

      private

      def generate_models_and_migrations
        say "\nGenerating models and migrations...", :blue

        begin
          # Generate passkey model and migration
          invoke "devise:webauthn:passkey_model", [], resource_name: options[:resource_name]

          # Generate webauthn_id column if needed
          invoke "devise:webauthn:webauthn_id", [], resource_name: options[:resource_name]

          # Generate Stimulus controller if needed
          invoke "devise:webauthn:stimulus"

          say "✓ All models and migrations generated successfully", :green
        rescue StandardError => e
          say "Error during generation: #{e.message}", :red
          say "You can run individual generators manually:", :yellow
          say "  rails generate devise:webauthn:passkey_model", :cyan
          say "  rails generate devise:webauthn:webauthn_id", :cyan
          say "  rails generate devise:webauthn:stimulus", :cyan
        end
      end

      def show_install_completion # rubocop:disable Metrics/AbcSize
        say "\n#{'=' * 60}", :green
        say "✅ DeviseWebauthn configuration installed!", :green
        say "=" * 60, :green

        say "\n📋 Next steps:", :blue
        say "1. Review and customize your base configuration in:", :white
        say "   config/initializers/webauthn.rb", :cyan

        say "\n4. Add :passkey_authenticatable to your User model:", :white
        say "   devise :database_authenticatable, :passkey_authenticatable", :cyan

        say "\n2. Run the migrations:", :white
        say "   rails db:migrate", :cyan

        say "\n3. Add passkey login to your sign-in view:", :white
        say "   <%= login_with_passkey_button(\"Sign in with Passkey\") %>", :yellow

        say "\n4. Create passkeys with form:", :white
        say "   <%= create_passkey_form do |f| %>", :yellow
        say "   <%= f.label :name, 'Passkey name' %>", :yellow
        say "   <%= f.text_field :name, required: true %>", :yellow
        say "   <%= f.submit 'Create Passkey' %>", :yellow
        say "   <% end %>", :yellow

        say "\n🎉 Your app is ready for WebAuthn passkey authentication!", :green
      end
    end
  end
end
