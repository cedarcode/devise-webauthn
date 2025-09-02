# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/webauthn_id/webauthn_id_generator"

RSpec.describe Devise::Webauthn::WebauthnIdGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
    allow(generator_instance).to receive(:invoke)
    invoke generator_instance
  end

  context "when using default resource name" do
    let(:generator_instance) { generator }

    it "invokes the active_record:migration generator with correct arguments" do
      expect(generator).to have_received(:invoke).with("active_record:migration",
                                                       ["add_webauthn_id_to_users", "webauthn_id:string:uniq"])
    end
  end

  context "when using a custom resource name" do
    let(:generator_instance) { generator([destination_root], ["--resource_name=admin"]) }

    it "invokes the active_record:migration generator with correct arguments" do
      expect(generator).to have_received(:invoke).with("active_record:migration",
                                                       ["add_webauthn_id_to_admins", "webauthn_id:string:uniq"])
    end
  end
end
