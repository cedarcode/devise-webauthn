# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/webauthn_credential_model/webauthn_credential_model_generator"

RSpec.describe Devise::Webauthn::WebauthnCredentialModelGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
    create_webauthn_credential_model_file
    allow(generator_instance).to receive(:invoke)
    invoke generator_instance
  end

  context "when using default resource name" do
    let(:generator_instance) { generator }

    it "invokes the active_record:model generator with correct arguments" do
      expect(generator).to have_received(:invoke).with("active_record:model",
                                                       ["webauthn_credential"],
                                                       migration: false)
    end

    it "create migration for creating webauthn credentials" do
      assert_migration "db/migrate/create_webauthn_credentials.rb" do |migration|
        assert_instance_method :change, migration do |method_body|
          assert_match(/t\.references :user, null: false, foreign_key: true/, method_body)
        end
      end
    end

    it "injects validations into the Passkey model" do
      assert_file "app/models/webauthn_credential.rb",
                  /validates :external_id, :public_key, :name, :sign_count, presence: true/
      assert_file "app/models/webauthn_credential.rb", /validates :external_id, uniqueness: true/
    end
  end

  context "when using a custom resource name" do
    let(:generator_instance) { generator([destination_root], ["--resource_name=admin"]) }

    it "invokes the active_record:model generator with correct arguments" do
      expect(generator).to have_received(:invoke).with("active_record:model",
                                                       ["webauthn_credential"],
                                                       migration: false)
    end

    it "create migration for creating webauthn credentials with correct association" do
      assert_migration "db/migrate/create_webauthn_credentials.rb" do |migration|
        assert_instance_method :change, migration do |method_body|
          assert_match(/t\.references :admin, null: false, foreign_key: true/, method_body)
        end
      end
    end
  end
end

def create_webauthn_credential_model_file
  FileUtils.mkdir_p(File.join(destination_root, "app/models"))
  File.write(File.join(destination_root, "app/models/webauthn_credential.rb"), "class WebauthnCredential\nend\n")
end
