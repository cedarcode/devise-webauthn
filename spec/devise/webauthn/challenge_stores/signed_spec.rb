# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe Devise::Webauthn::ChallengeStores::Signed do
  include ActiveSupport::Testing::TimeHelpers

  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }
  let(:issued_challenge) { store_for(nil).write(:passkey_authentication, WebAuthn::Credential.options_for_get.challenge) }

  def store_for(credential)
    described_class.new(instance_double(ActionDispatch::Request, params: { public_key_credential: credential }))
  end

  def store_signing(challenge)
    client.create(challenge: WebAuthn::Credential.options_for_get.challenge)
    store_for(client.get(challenge: challenge))
  end

  it "accepts the challenge it issued when the credential signs it" do
    store = store_signing(issued_challenge)

    expect(store.pending?(:passkey_authentication)).to be(true)
    expect(store.consume(:passkey_authentication)).to eq(issued_challenge)
  end

  it "rejects a challenge it did not issue" do
    store = store_signing(WebAuthn::Credential.options_for_get.challenge)

    expect(store.consume(:passkey_authentication)).to be_nil
  end

  it "rejects a challenge issued for another purpose" do
    store = store_signing(issued_challenge)

    expect(store.consume(:two_factor_authentication)).to be_nil
  end

  it "expires challenges" do
    store = store_signing(issued_challenge)

    travel_to(described_class.expires_in.from_now + 1.second) do
      expect(store.consume(:passkey_authentication)).to be_nil
    end
  end

  it "accepts a challenge more than once until it expires, because it keeps no state" do
    store = store_signing(issued_challenge)

    expect(store.consume(:passkey_authentication)).to eq(issued_challenge)
    expect(store.consume(:passkey_authentication)).to eq(issued_challenge)
  end

  it "ignores malformed credentials" do
    [nil, "{}", {}, { "response" => "x" }, { "response" => { "clientDataJSON" => "%%%" } }].each do |malformed|
      expect(store_for(malformed).pending?(:passkey_authentication)).to be(false)
    end
  end
end
