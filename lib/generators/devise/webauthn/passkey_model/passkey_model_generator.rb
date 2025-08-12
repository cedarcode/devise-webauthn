# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Devise
  module Webauthn
    class PasskeyModelGenerator < Rails::Generators::Base
      namespace "devise:webauthn:passkey_model"
      source_root File.expand_path("templates", __dir__)

      desc "Generate a Passkey model with the required fields for WebAuthn"
      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def generate_model
        invoke "active_record:model", [
          "passkey",
          "external_id:string:uniq",
          "name:string",
          "public_key:text",
          "sign_count:bigint",
          "#{user_model_name}:references"
        ]
      end

      def inject_passkey_content
        inject_into_file("app/models/passkey.rb", before: /^end\s*$/) do
          <<~RUBY.indent(2)
            validates :external_id, :public_key, :name, :sign_count, presence: true
            validates :external_id, uniqueness: true
          RUBY
        end
      end

      def show_instructions
        say <<~MSG
          Passkey model has been generated! Next steps:

          1. Run the migration:
             rails db:migrate

          2. Make sure your User model includes :passkey_authenticatable in the devise line:
             devise :database_authenticatable, :passkey_authenticatable, ...
        MSG
      end

      private

      def user_model_name
        options[:resource_name].underscore
      end
    end
  end
end
