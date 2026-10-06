# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Webauthn::ChallengeStoreAccess do
  let(:request) { instance_double(ActionDispatch::Request, session: {}) }
  let(:host) do
    Class.new do
      include Devise::Webauthn::ChallengeStoreAccess

      attr_reader :request

      def initialize(request)
        @request = request
      end

      public :challenge_store
    end.new(request)
  end

  around do |example|
    original_store = Devise::Webauthn.challenge_store
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
  end

  it "uses the session store by default" do
    expect(host.challenge_store).to be_a(Devise::Webauthn::ChallengeStores::Session)
  end

  it "resolves a symbol to the matching store" do
    Devise::Webauthn.challenge_store = :session

    expect(host.challenge_store).to be_a(Devise::Webauthn::ChallengeStores::Session)
  end

  it "uses a store class as given" do
    Devise::Webauthn.challenge_store = MemoryChallengeStore

    expect(host.challenge_store).to be_a(MemoryChallengeStore)
  end

  it "raises on an unknown symbol" do
    Devise::Webauthn.challenge_store = :unknown

    expect { host.challenge_store }.to raise_error(NameError)
  end
end
