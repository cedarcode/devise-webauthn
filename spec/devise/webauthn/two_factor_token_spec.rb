# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Webauthn::TwoFactorToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:resource) { instance_double(Account, id: 1) }
  let(:token) { described_class.generate(resource, scope: :account, remember_me: true) }

  it "reads back the resource id and remember me" do
    expect(described_class.read(token, scope: :account)).to include("id" => 1, "remember_me" => true)
  end

  it "does not expose the payload" do
    decoded = token.split("--").map { |part| Base64.strict_decode64(part) }.join

    expect(decoded).not_to include("remember_me")
  end

  it "returns nil for another scope" do
    expect(described_class.read(token, scope: :admin)).to be_nil
  end

  it "returns nil after it expires" do
    token

    travel_to(described_class.expires_in.from_now + 1.second) do
      expect(described_class.read(token, scope: :account)).to be_nil
    end
  end

  it "returns nil for a tampered token" do
    expect(described_class.read("#{token}x", scope: :account)).to be_nil
  end

  it "returns nil when the token is missing" do
    expect(described_class.read(nil, scope: :account)).to be_nil
  end
end
