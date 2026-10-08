# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe "Passkey sign-in with the cache challenge store", type: :request do
  let(:user) do
    Account.create!(email: "test@example.com", password: "password123", webauthn_id: WebAuthn.generate_user_id)
  end
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }
  let!(:passkey) do
    credential = WebAuthn::Credential.from_create(
      client.create(challenge: WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32)))
    )
    user.passkeys.create!(external_id: credential.id, name: "My Passkey", public_key: credential.public_key,
                          sign_count: credential.sign_count)
  end

  around do |example|
    original_store = Devise::Webauthn.challenge_store
    original_cache = Devise::Webauthn::ChallengeStores::Cache.cache

    Devise::Webauthn.challenge_store = :cache
    Devise::Webauthn::ChallengeStores::Cache.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
    Devise::Webauthn::ChallengeStores::Cache.cache = original_cache
  end

  def assertion_for_new_challenge
    post account_passkey_authentication_options_path
    challenge = response.parsed_body["challenge"]
    reset!

    client.get(challenge: challenge, allow_credentials: [passkey.external_id], user_verified: true,
               user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id))
  end

  it "signs in from a different session than the one that requested the challenge" do
    post account_session_path, params: { public_key_credential: assertion_for_new_challenge.to_json }

    expect(response).to redirect_to(root_path)
    expect(controller.current_account).to eq(user)
  end

  it "rejects a challenge that was already used" do
    params = { public_key_credential: assertion_for_new_challenge.to_json }
    post account_session_path, params: params
    reset!

    post account_session_path, params: params

    expect(controller.current_account).to be_nil
  end
end
