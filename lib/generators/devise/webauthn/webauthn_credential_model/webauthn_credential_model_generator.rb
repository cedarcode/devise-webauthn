# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Devise
  module Webauthn
    class WebauthnCredentialModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      hide!
      namespace "devise:webauthn:webauthn_credential_model"

      source_root File.expand_path("templates", __dir__)

      desc "Generate a WebauthnCredential model with the required fields for WebAuthn"
      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def generate_model
        invoke "active_record:model", ["webauthn_credential"], migration: false
      end

      # TODO: Remove this in favor of strandard model generator with
      # not null modifier (`!`) once we drop support for Rails < 8.
      def generate_migration
        migration_template "webauthn_credential_migration.rb.erb", "db/migrate/create_webauthn_credentials.rb"
      end

      def inject_webauthn_credential_content
        inject_into_file("app/models/webauthn_credential.rb", before: /^end\s*$/) do
          <<~RUBY.indent(2)
            validates :external_id, :public_key, :name, :sign_count, presence: true
            validates :external_id, uniqueness: true

            enum :authentication_factor, { first_factor: 0, second_factor: 1 }

            scope :passkey, -> { first_factor }
          RUBY
        end
      end

      def show_instructions
        say <<~MSG
          WebauthnCredential model has been generated! Next steps:

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
