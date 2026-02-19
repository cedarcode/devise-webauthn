# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/webauthn_id/webauthn_id_generator"

RSpec.describe Devise::Webauthn::WebauthnIdGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
    invoke generator_instance
  end

  context "when using default resource name" do
    let(:generator_instance) { generator }

    it "creates a migration that adds webauthn_id to users" do
      assert_migration "db/migrate/add_webauthn_id_to_users.rb" do |migration|
        assert_match(/add_column :users, :webauthn_id, :string/, migration)
        assert_match(/add_index :users, :webauthn_id, unique: true/, migration)
      end
    end

    it "creates a migration that backfills existing records" do
      assert_migration "db/migrate/add_webauthn_id_to_users.rb" do |migration|
        assert_match(/SELECT id FROM users WHERE webauthn_id IS NULL/, migration)
        assert_match(/WebAuthn\.generate_user_id/, migration)
      end
    end
  end

  context "when using a custom resource name" do
    let(:generator_instance) { generator([destination_root], ["--resource_name=admin"]) }

    it "creates a migration that adds webauthn_id to admins" do
      assert_migration "db/migrate/add_webauthn_id_to_admins.rb" do |migration|
        assert_match(/add_column :admins, :webauthn_id, :string/, migration)
        assert_match(/add_index :admins, :webauthn_id, unique: true/, migration)
      end
    end
  end
end
