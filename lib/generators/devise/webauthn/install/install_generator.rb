# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Devise::Webauthn configuration into your application"

      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def install
        say "Installing DeviseWebauthn configuration...", :green

        template "webauthn.rb", "config/initializers/webauthn.rb"
        say "Created initializer: config/initializers/webauthn.rb", :green
      end

      def generate_webauthn_credential_model
        invoke "devise:webauthn:webauthn_credential_model", [], resource_name: options[:resource_name]
      end

      def generate_webauthn_id_column
        invoke "devise:webauthn:webauthn_id", [], resource_name: options[:resource_name]
      end

      def final_message
        say "\nAlmost done! Now edit `config/initializers/webauthn.rb` and set the `allowed_origins` for your app.",
            :yellow
      end
    end
  end
end
