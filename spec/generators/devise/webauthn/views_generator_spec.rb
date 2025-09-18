# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/views_generator"

RSpec.describe Devise::Webauthn::ViewsGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
    invoke generator_instance
  end

  context "when using default scope" do
    let(:generator_instance) { generator }

    it "copies the views to the correct location" do
      assert_file "app/views/devise/sessions/new.html.erb"
      assert_file "app/views/devise/passkeys/new.html.erb"
    end
  end

  context "when using a custom scope" do
    let(:generator_instance) { generator(["Admin"]) }

    it "copies the views to the correct location" do
      assert_file "app/views/admins/sessions/new.html.erb"
      assert_file "app/views/admins/passkeys/new.html.erb"
    end
  end
end
