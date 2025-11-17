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
                                                       ["webauthn_credential", "external_id:string:uniq", "name:string",
                                                        "public_key:text", "sign_count:integer{8}", "user:references"])
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
                                                       ["webauthn_credential", "external_id:string:uniq", "name:string",
                                                        "public_key:text", "sign_count:integer{8}", "admin:references"])
    end
  end
end

def create_webauthn_credential_model_file
  FileUtils.mkdir_p(File.join(destination_root, "app/models"))
  File.write(File.join(destination_root, "app/models/webauthn_credential.rb"), "class WebauthnCredential\nend\n")
end
