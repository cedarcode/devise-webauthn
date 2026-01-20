# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe "Passkey authentication flow", type: :request do
  let(:password) { "password123" }
  let(:user) { Account.create!(email: "test@example.com", password: password) }
  let(:origin) { WebAuthn.configuration.allowed_origins.first }
  let(:client) { WebAuthn::FakeClient.new(origin) }

  def create_passkey_for(account, fake_client)
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

  def generate_assertion(fake_client, challenge:, credential:)
    fake_client.get(
      challenge: challenge,
      allow_credentials: [credential.external_id],
      user_verified: true
    )
  end

  describe "sign-in with passkeys" do
    let!(:passkey) { create_passkey_for(user, client) }

    it "completes authentication with valid credential" do
      get new_account_session_path

      assertion = generate_assertion(
        client,
        challenge: session[:authentication_challenge],
        credential: passkey
      )

      expect do
        post account_session_path, params: {
          public_key_credential: assertion.to_json
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(I18n.t("devise.sessions.signed_in"))
        expect(controller.current_account).to eq(user)
        expect(session[:authentication_challenge]).to be_nil
      end.to change { passkey.reload.sign_count }.by(1)
    end

    it "rejects sign-in with non-existent credential" do
      get new_account_session_path

      assertion = generate_assertion(
        client,
        challenge: session[:authentication_challenge],
        credential: passkey
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
        allow_credentials: [passkey.external_id]
      )

      post account_session_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Log in")
      expect(flash[:alert]).to eq(I18n.t("devise.failure.passkey_verification_failed"))
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
end
