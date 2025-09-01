# frozen_string_literal: true

require "rails/generators"
require_relative "files_configurator"
require_relative "engine_configurator"

module Devise
  module Webauthn
    class InstallGenerator < Rails::Generators::Base
      include FilesConfigurator
      include EngineConfigurator

      source_root File.expand_path("templates", __dir__)

      desc "Install Devise::Webauthn configuration into your application"

      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def install
        say "Installing DeviseWebauthn configuration...", :green

        setup_configuration_files
        mount_passkeys_engine
      end

      def generate_passkey_model
        invoke "devise:webauthn:passkey_model", [], resource_name: options[:resource_name]
      rescue StandardError => e
        say "Error during passkey model generation: #{e.message}", :red
      end

      def generate_webauthn_id_column
        invoke "devise:webauthn:webauthn_id", [], resource_name: options[:resource_name]
      rescue StandardError => e
        say "Error during webauthn column generation: #{e.message}", :red
      end

      def generate_stimulus_controller
        invoke "devise:webauthn:stimulus"
      rescue StandardError => e
        say "Error during stimulus controller generation: #{e.message}", :red
      end

      def final_message
        say ""
        say "Almost done! Now edit `config/initializers/webauthn.rb` and set the `allowed_origins` for your app.",
            :yellow
      end
    end
  end
end
