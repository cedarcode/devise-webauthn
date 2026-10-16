# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Webauthn::PublicKeyCredentialParam do
  let(:credential) { { "type" => "public-key", "response" => { "clientDataJSON" => "abc" } } }

  it "parses a JSON string" do
    expect(described_class.parse(credential.to_json)).to eq(credential)
  end

  it "accepts controller params" do
    expect(described_class.parse(ActionController::Parameters.new(credential))).to eq(credential)
  end

  it "returns nil for invalid JSON" do
    expect(described_class.parse("not json")).to be_nil
  end

  it "returns nil for JSON that is not an object" do
    expect(described_class.parse("[]")).to be_nil
  end

  it "returns nil for a credential without a response" do
    expect(described_class.parse({ "type" => "public-key" }.to_json)).to be_nil
  end

  it "returns nil when the param is missing" do
    expect(described_class.parse(nil)).to be_nil
  end
end
