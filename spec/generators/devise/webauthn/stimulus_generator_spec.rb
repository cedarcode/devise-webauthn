# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/stimulus/stimulus_generator"

RSpec.describe Devise::Webauthn::StimulusGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
    invoke generator
  end

  it "copies the Stimulus controller to the correct location" do
    expect(File).to exist(File.join(destination_root, "app/javascript/controllers/passkeys_controller.js"))
  end
end
