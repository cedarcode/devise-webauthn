# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Devise
  module Webauthn
    class PasskeyModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      namespace "devise:webauthn:passkey_model"
      source_root File.expand_path("templates", __dir__)

      desc "Generate a Passkey model with the required fields for WebAuthn"
      class_option :resource_name, type: :string, default: "user", desc: "The resource name for Devise (default: user)"

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

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
          passkey_model_content
        end
      end

      def show_instructions
        say <<~MSG
          Passkey model has been generated! Next steps:

          1. Run the migration:
             rails db:migrate

          2. Add webauthn_id field to your User model if not already done:
             rails generate devise:webauthn:webauthn_id

          3. Make sure your User model includes :passkey_authenticatable in the devise line:
             devise :database_authenticatable, :passkey_authenticatable, ...

          4. Your Passkey model is ready to use with DeviseWebauthn!
             (The has_many :passkeys association is automatically added by the PasskeyAuthenticatable module)
        MSG
      end

      private

      def passkey_model_content
        <<-RUBY

  validates :external_id, :public_key, :name, :sign_count, presence: true
  validates :external_id, uniqueness: true
        RUBY
      end

      def user_model_name
        options[:resource_name].underscore
      end
    end
  end
end
