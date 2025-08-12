# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Devise
  module Webauthn
    class WebauthnIdGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      namespace "devise:webauthn:webauthn_id"
      source_root File.expand_path("templates", __dir__)

      desc "Add webauthn_id field to User model"
      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def generate_migration
        migration_template(
          "add_webauthn_id_migration.rb.erb",
          "db/migrate/add_webauthn_id_to_#{user_table_name}.rb"
        )
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
