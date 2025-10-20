# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/controllers_generator"

RSpec.describe Devise::Webauthn::ControllersGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
  end

  context "when no scope is passed" do
    let(:generator_instance) { generator }

    it "does not create anything" do
      expect { invoke generator_instance }.to raise_error(Thor::RequiredArgumentMissingError,
                                                          "No value provided for required arguments 'scope'")
      assert_no_file "app/controllers/passkeys_controller.rb"
    end
  end

  context "when using a custom scope" do
    let(:generator_instance) { generator(["users"]) }

    it "create controllers properly scoped with scope param" do
      invoke generator_instance

      assert_file "app/controllers/users/passkeys_controller.rb", /Users::PasskeysController/
    end
  end
end
