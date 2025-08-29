# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/install/install_generator"

RSpec.describe Devise::Webauthn::InstallGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  context "when using default resource name" do
    before do
      prepare_destination
      add_config_directory
      add_routes
      allow(generator).to receive(:invoke)
      generator.invoke_all
    end

    it "creates a weabauthn initializer" do
      expect(File).to exist(File.join(destination_root, "config/initializers/webauthn.rb"))
    end

    it "mounts the engine in routes.rb" do
      routes = File.read(File.join(destination_root, "config/routes.rb"))
      expect(routes).to include('mount Devise::Webauthn::Engine, at: "/devise-webauthn"')
    end

    it "invokes the passkey model generator" do
      expect(generator).to have_received(:invoke)
        .with("devise:webauthn:passkey_model", [], resource_name: "user")
    end

    it "invokes the webauthn_id column generator" do
      expect(generator).to have_received(:invoke)
        .with("devise:webauthn:webauthn_id", [], resource_name: "user")
    end

    it "invokes the stimulus controller generator" do
      expect(generator).to have_received(:invoke)
        .with("devise:webauthn:stimulus")
    end
  end

  context "when using a custom resource name" do
    before do
      prepare_destination
      add_config_directory
      add_routes
      generator([destination_root], ["--resource_name=admin"])
      allow(generator).to receive(:invoke)
      generator.invoke_all
    end

    it "invokes the passkey model generator with the custom resource name" do
      expect(generator).to have_received(:invoke)
        .with("devise:webauthn:passkey_model", [], resource_name: "admin")
    end

    it "invokes the webauthn_id column generator with the custom resource name" do
      expect(generator).to have_received(:invoke)
        .with("devise:webauthn:webauthn_id", [], resource_name: "admin")
    end
  end
end

def add_config_directory
  FileUtils.mkdir_p(File.join(destination_root, "config"))
end

def add_routes
  File.write(File.join(destination_root, "config", "routes.rb"), <<~CONTENT)
    Rails.application.routes.draw do
    end
  CONTENT
end
