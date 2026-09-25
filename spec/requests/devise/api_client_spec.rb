# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe "API client without a session", type: :request do
  let(:password) { "password123" }
  let(:user) { Account.create!(email: "test@example.com", password: password, webauthn_id: WebAuthn.generate_user_id) }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  around do |example|
    original_store = Devise::Webauthn.challenge_store
    original_cache = Devise::Webauthn::ChallengeStores::Cache.cache
    original_skip_session_storage = Account.skip_session_storage

    Devise::Webauthn.challenge_store = Devise::Webauthn::ChallengeStores::Cache
    Devise::Webauthn::ChallengeStores::Cache.cache = ActiveSupport::Cache::MemoryStore.new
    Account.skip_session_storage = %i[http_auth params_auth]
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
    Devise::Webauthn::ChallengeStores::Cache.cache = original_cache
    Account.skip_session_storage = original_skip_session_storage
  end

  # Every request starts a new integration session, so no cookie carries state between requests.
  def api_post(path, body = {})
    reset!
    post path, params: body.to_json,
               headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
  end

  def create_credential_for(account, factor)
    credential = WebAuthn::Credential.from_create(
      client.create(challenge: WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32)))
    )
    account.webauthn_credentials.create!(external_id: credential.id, name: "Key", public_key: credential.public_key,
                                         sign_count: credential.sign_count, authentication_factor: factor)
  end

  describe "passkey sign-in" do
    let!(:passkey) { create_credential_for(user, :first_factor) }

    def passkey_assertion(challenge)
      client.get(challenge: challenge, allow_credentials: [passkey.external_id], user_verified: true,
                 user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id))
    end

    def request_challenge
      api_post account_passkey_authentication_options_path
      response.parsed_body["challenge"]
    end

    it "signs in with the credential sent as a JSON object and does not store the user in the session" do
      api_post account_session_path, public_key_credential: passkey_assertion(request_challenge)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["email"]).to eq(user.email)
      expect(session["warden.user.account.key"]).to be_nil
    end

    it "rejects a challenge that was already used" do
      challenge = request_challenge
      api_post account_session_path, public_key_credential: passkey_assertion(challenge)

      api_post account_session_path, public_key_credential: passkey_assertion(challenge)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a challenge the server never issued" do
      challenge = WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32))

      api_post account_session_path, public_key_credential: passkey_assertion(challenge)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a malformed credential" do
      api_post account_session_path, public_key_credential: "not json"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
