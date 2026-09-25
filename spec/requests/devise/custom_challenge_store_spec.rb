# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe "Custom challenge store", type: :request do
  let(:memory_store_class) do
    Class.new do
      def self.challenges
        @challenges ||= {}
      end

      def initialize(_request); end

      def write(purpose, challenge)
        self.class.challenges[purpose] = challenge
      end

      def pending?(purpose, _credential_json)
        self.class.challenges.key?(purpose)
      end

      def consume(purpose, _credential_json)
        self.class.challenges.delete(purpose)
      end
    end
  end

  let(:user) { Account.create!(email: "test@example.com", password: "password123") }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }
  let!(:passkey) do
    user.update!(webauthn_id: WebAuthn.generate_user_id)
    credential = WebAuthn::Credential.from_create(
      client.create(challenge: WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32)))
    )
    user.passkeys.create!(external_id: credential.id, name: "My Passkey",
                          public_key: credential.public_key, sign_count: credential.sign_count)
  end

  around do |example|
    original_store = Devise::Webauthn.challenge_store
    Devise::Webauthn.challenge_store = memory_store_class
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
  end

  def sign_in_with_passkey(challenge)
    assertion = client.get(
      challenge: challenge,
      allow_credentials: [passkey.external_id],
      user_verified: true,
      user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id)
    )

    post account_session_path, params: { public_key_credential: assertion.to_json }
  end

  it "signs in with a passkey without keeping the challenge in the session" do
    post account_passkey_authentication_options_path
    challenge = response.parsed_body["challenge"]

    expect(memory_store_class.challenges).to eq(passkey_authentication: challenge)
    expect(session[:authentication_challenge]).to be_nil

    sign_in_with_passkey(challenge)

    expect(controller.current_account).to eq(user)
  end

  it "consumes the challenge so it cannot be used twice" do
    post account_passkey_authentication_options_path
    challenge = response.parsed_body["challenge"]
    sign_in_with_passkey(challenge)
    expect(memory_store_class.challenges).to be_empty
    delete destroy_account_session_path

    sign_in_with_passkey(challenge)

    expect(controller.current_account).to be_nil
  end
end
