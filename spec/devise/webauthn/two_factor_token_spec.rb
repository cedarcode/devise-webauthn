# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Webauthn::TwoFactorToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:resource) { instance_double(Account, id: 1) }
  let(:token) { described_class.generate(resource, scope: :account, remember_me: true) }

  it "reads back the resource id and remember me" do
    expect(described_class.read(token, scope: :account)).to include("id" => 1, "remember_me" => true)
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

  it "can be consumed more than once without the cache state store" do
    payload = described_class.read(token, scope: :account)

    expect([described_class.consume(payload), described_class.consume(payload)]).to eq([true, true])
    expect(described_class.read(token, scope: :account)).to be_present
  end

  context "with the cache state store" do
    around do |example|
      original_store = Devise::Webauthn.state_store
      original_cache = Devise::Webauthn::StateStores::Cache.cache
      Devise::Webauthn.state_store = :cache
      Devise::Webauthn::StateStores::Cache.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Devise::Webauthn.state_store = original_store
      Devise::Webauthn::StateStores::Cache.cache = original_cache
    end

    it "is consumed once" do
      payload = described_class.read(token, scope: :account)

      expect([described_class.consume(payload), described_class.consume(payload)]).to eq([true, false])
    end

    it "returns nil after it is consumed" do
      described_class.consume(described_class.read(token, scope: :account))

      expect(described_class.read(token, scope: :account)).to be_nil
    end

    it "returns nil when the cache entry is missing" do
      token
      Devise::Webauthn::StateStores::Cache.cache.clear

      expect(described_class.read(token, scope: :account)).to be_nil
    end
  end
end
