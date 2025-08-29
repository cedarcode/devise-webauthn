# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/webauthn_id/webauthn_id_generator"

RSpec.describe Devise::Webauthn::WebauthnIdGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  context "when using default resource name" do
    before do
      prepare_destination
      allow(generator).to receive(:invoke)
      invoke generator
    end

    it "invokes the active_record:migration generator with correct arguments" do
      expect(generator).to have_received(:invoke).with("active_record:migration",
                                                       ["add_webauthn_id_to_users", "webauthn_id:string:uniq"])
    end
  end

  context "when using a custom resource name" do
    before do
      prepare_destination
      generator([destination_root], ["--resource_name=admin"])
      allow(generator).to receive(:invoke)
      invoke generator
    end

    it "invokes the active_record:migration generator with correct arguments" do
      expect(generator).to have_received(:invoke).with("active_record:migration",
                                                       ["add_webauthn_id_to_admins", "webauthn_id:string:uniq"])
    end
  end
end
