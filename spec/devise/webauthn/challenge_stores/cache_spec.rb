# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe Devise::Webauthn::ChallengeStores::Cache do
  include ActiveSupport::Testing::TimeHelpers

  let(:store) { described_class.new(instance_double(ActionDispatch::Request)) }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }
  let(:challenge) { WebAuthn::Credential.options_for_get.challenge }
  let(:credential) do
    client.create(challenge: WebAuthn::Credential.options_for_get.challenge)
    client.get(challenge: challenge)
  end

  around do |example|
    original_cache = described_class.cache
    described_class.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    described_class.cache = original_cache
  end

  it "finds the challenge through the credential's client data and consumes it once" do
    store.write(:passkey_authentication, challenge)

    expect(store.pending?(:passkey_authentication, credential)).to be(true)
    expect(store.consume(:passkey_authentication, credential)).to eq(challenge)
    expect(store.consume(:passkey_authentication, credential)).to be_nil
  end

  it "keeps challenges for different purposes apart" do
    store.write(:two_factor_authentication, challenge)

    expect(store.pending?(:passkey_authentication, credential)).to be(false)
  end

  it "expires challenges" do
    store.write(:passkey_authentication, challenge)

    travel_to(described_class.expires_in.from_now + 1.second) do
      expect(store.consume(:passkey_authentication, credential)).to be_nil
    end
  end

  it "ignores malformed credentials" do
    [nil, "{}", {}, { "response" => "x" }, { "response" => { "clientDataJSON" => "%%%" } }].each do |malformed|
      expect(store.pending?(:passkey_authentication, malformed)).to be(false)
    end
  end
end
