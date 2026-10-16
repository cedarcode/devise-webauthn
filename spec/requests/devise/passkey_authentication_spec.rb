# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe "Passkey authentication flow", type: :request do
  let(:password) { "password123" }
  let(:user) { Account.create!(email: "test@example.com", password: password) }
  let(:origin) { WebAuthn.configuration.allowed_origins.first }
  let(:client) { WebAuthn::FakeClient.new(origin) }

  around do |example|
    original_store = Devise::Webauthn.challenge_store
    Devise::Webauthn.challenge_store = MemoryChallengeStore
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
    MemoryChallengeStore.reset
  end

  def stored_challenge
    MemoryChallengeStore.challenges[:passkey_authentication]
  end

  def create_passkey_for(account, fake_client)
    account.update!(webauthn_id: WebAuthn.generate_user_id)
    challenge = WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32))
    raw_credential = fake_client.create(challenge: challenge)
    webauthn_credential = WebAuthn::Credential.from_create(raw_credential)

    account.passkeys.create!(
      external_id: webauthn_credential.id,
      name: "My Passkey",
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count
    )
  end

  def generate_assertion(fake_client, challenge:, credential:, user_handle: nil)
    fake_client.get(
      challenge: challenge,
      allow_credentials: [credential.external_id],
      user_verified: true,
      user_handle: user_handle
    )
  end

  describe "sign-in with passkeys" do
    let!(:passkey) { create_passkey_for(user, client) }

    before do
      post account_passkey_authentication_options_path # To store the challenge
    end

    it "completes authentication with valid credential" do
      get new_account_session_path

      assertion = generate_assertion(
        client,
        challenge: stored_challenge,
        credential: passkey,
        user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id)
      )

      expect do
        post account_session_path, params: {
          public_key_credential: assertion.to_json
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(I18n.t("devise.sessions.signed_in"))
        expect(controller.current_account).to eq(user)
        expect(stored_challenge).to be_nil
      end.to change { passkey.reload.sign_count }.by(1)
    end

    it "consumes the challenge so it cannot be used twice" do
      assertion = generate_assertion(
        client,
        challenge: stored_challenge,
        credential: passkey,
        user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id)
      )
      params = { public_key_credential: assertion.to_json }

      post account_session_path, params: params
      expect(controller.current_account).to eq(user)
      delete destroy_account_session_path

      post account_session_path, params: params

      expect(controller.current_account).to be_nil
    end

    it "rejects sign-in with non-existent credential" do
      get new_account_session_path

      assertion = generate_assertion(
        client,
        challenge: stored_challenge,
        credential: passkey,
        user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id)
      )
      passkey.destroy!

      post account_session_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Log in")
      expect(flash[:alert]).to eq(I18n.t("devise.failure.passkey_not_found"))
      expect(controller.current_account).to be_nil
    end

    it "fails with invalid challenge" do
      get new_account_session_path

      assertion = client.get(
        challenge: WebAuthn.configuration.encoder.encode("invalid_challenge"),
        allow_credentials: [passkey.external_id],
        user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id)
      )

      post account_session_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Log in")
      expect(flash[:alert]).to eq(I18n.t("devise.failure.passkey_verification_failed"))
      expect(controller.current_account).to be_nil
    end

    it "rejects sign-in when userHandle is missing from the response" do
      get new_account_session_path

      assertion = client.get(
        challenge: stored_challenge,
        allow_credentials: [passkey.external_id],
        user_verified: true
      )

      post account_session_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash[:alert]).to eq(I18n.t("devise.failure.passkey_not_found"))
      expect(controller.current_account).to be_nil
    end

    it "rejects sign-in when userHandle does not match the passkey owner" do
      other_user = Account.create!(email: "other@example.com", password: password,
                                   webauthn_id: WebAuthn.generate_user_id)

      get new_account_session_path

      assertion = client.get(
        challenge: stored_challenge,
        allow_credentials: [passkey.external_id],
        user_verified: true,
        user_handle: WebAuthn.configuration.encoder.decode(other_user.webauthn_id)
      )

      post account_session_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash[:alert]).to eq(I18n.t("devise.failure.passkey_not_found"))
      expect(controller.current_account).to be_nil
    end

    it "fails when credential param is missing" do
      post account_session_path, params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Log in")
      expect(flash[:alert]).to match(/Invalid email or password/i) # TODO: CHANGE THIS
      expect(controller.current_account).to be_nil
    end
  end

  context "with a JSON request from a client without a session" do
    include_context "with a JSON client without a session"

    let!(:passkey) { create_passkey_for(user, client) }

    def request_challenge
      json_post account_passkey_authentication_options_path
      response.parsed_body["challenge"]
    end

    def assertion_for(challenge)
      generate_assertion(client, challenge: challenge, credential: passkey,
                                 user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id))
    end

    it "signs in with the credential sent as a JSON object and does not store the user in the session" do
      json_post account_session_path, public_key_credential: assertion_for(request_challenge)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["email"]).to eq(user.email)
      expect(session["warden.user.account.key"]).to be_nil
    end

    it "rejects a challenge that was already used" do
      challenge = request_challenge
      json_post account_session_path, public_key_credential: assertion_for(challenge)

      json_post account_session_path, public_key_credential: assertion_for(challenge)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a challenge the server never issued" do
      challenge = WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32))

      json_post account_session_path, public_key_credential: assertion_for(challenge)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a malformed credential" do
      json_post account_session_path, public_key_credential: "not json"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
