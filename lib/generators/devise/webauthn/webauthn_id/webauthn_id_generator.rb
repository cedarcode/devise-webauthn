# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Devise
  module Webauthn
    class WebauthnIdGenerator < Rails::Generators::Base
      namespace "devise:webauthn:webauthn_id"

      desc "Add webauthn_id field to User model"
      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def generate_migration
        invoke "active_record:migration", [
          "add_webauthn_id_to_#{user_table_name}",
          "webauthn_id:string:uniq"
        ]
      end

      def show_instructions
        say <<~MSG
          WebAuthn ID field has been added! Next steps:

          1. Run the migration:
             rails db:migrate

          2. Make sure your User model includes :passkey_authenticatable in the devise line:
             devise :database_authenticatable, :passkey_authenticatable, ...
        MSG
      end

      private

      def user_table_name
        options[:resource_name].pluralize.underscore
      end
    end
  end
end
