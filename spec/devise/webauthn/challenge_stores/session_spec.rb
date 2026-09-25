# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Webauthn::ChallengeStores::Session do
  let(:session) { {} }
  let(:store) { described_class.new(instance_double(ActionDispatch::Request, session: session)) }

  it "keeps each purpose under its own session key" do
    store.write(:passkey_authentication, "passkey-challenge")
    store.write(:two_factor_authentication, "2fa-challenge")
    store.write(:registration, "registration-challenge")

    expect(session).to eq(
      authentication_challenge: "passkey-challenge",
      two_factor_authentication_challenge: "2fa-challenge",
      webauthn_challenge: "registration-challenge"
    )
  end

  it "reports a challenge as pending until it is consumed" do
    store.write(:passkey_authentication, "challenge")

    expect(store.pending?(:passkey_authentication, "{}")).to be(true)
    expect(store.consume(:passkey_authentication, "{}")).to eq("challenge")
    expect(store.pending?(:passkey_authentication, "{}")).to be(false)
  end

  it "returns nil when consuming a challenge that was never written" do
    expect(store.consume(:registration, "{}")).to be_nil
  end

  it "raises on an unknown purpose" do
    expect { store.write(:unknown, "challenge") }.to raise_error(KeyError)
  end
end
