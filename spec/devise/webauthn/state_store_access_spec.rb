# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Webauthn::StateStoreAccess do
  let(:request) { instance_double(ActionDispatch::Request, session: {}) }
  let(:host) do
    Class.new do
      include Devise::Webauthn::StateStoreAccess

      attr_reader :request

      def initialize(request)
        @request = request
      end

      public :state_store
    end.new(request)
  end

  around do |example|
    original_store = Devise::Webauthn.state_store
    example.run
  ensure
    Devise::Webauthn.state_store = original_store
  end

  it "uses the session store by default" do
    expect(host.state_store).to be_a(Devise::Webauthn::StateStores::Session)
  end

  it "resolves a symbol to the matching store" do
    Devise::Webauthn.state_store = :session

    expect(host.state_store).to be_a(Devise::Webauthn::StateStores::Session)
  end

  it "uses a store class as given" do
    Devise::Webauthn.state_store = MemoryStateStore

    expect(host.state_store).to be_a(MemoryStateStore)
  end

  it "raises on an unknown symbol" do
    Devise::Webauthn.state_store = :unknown

    expect { host.state_store }.to raise_error(NameError)
  end
end
