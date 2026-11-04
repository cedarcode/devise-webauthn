# frozen_string_literal: true

require "webauthn/fake_client"

RSpec.describe Devise::PasskeysController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  describe "POST #create" do
    let(:challenge) do
      authenticate_next_request_as(user)
      post account_passkey_registration_options_path, as: :json
      response.parsed_body["challenge"]
    end

    let(:public_key_credential) { client.create(challenge: challenge, user_verified: true) }

    def create_passkey(params)
      authenticate_next_request_as(user)
      post account_passkeys_path, params: { name: "My phone" }.merge(params), as: :json
    end

    it "creates a passkey and responds with 201 and no body" do
      expect { create_passkey(public_key_credential: public_key_credential) }.to change(user.passkeys, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.body).to be_empty
    end

    it "responds with 422 and an error message when verification fails" do
      create_passkey(public_key_credential: client.create(challenge: random_challenge, user_verified: true))

      expect(response).to have_http_status(422)
      expect(response.parsed_body["errors"]).to eq("base" => [I18n.t("devise.failure.passkey_verification_failed")])
    end

    it "responds with 422 and an error message when the credential has no response" do
      create_passkey(public_key_credential: { type: "public-key" })

      expect(response).to have_http_status(422)
      expect(response.parsed_body["errors"]).to eq("base" => [I18n.t("devise.failure.passkey_verification_failed")])
    end

    it "responds with 422 when the credential is missing" do
      create_passkey({})

      expect(response).to have_http_status(422)
    end

    it "responds with 401 when the request is not authenticated" do
      post account_passkeys_path, params: { name: "My phone", public_key_credential: public_key_credential }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE #destroy" do
    let!(:passkey) do
      user.passkeys.create!(external_id: "external-id", name: "My Passkey", public_key: "public-key", sign_count: 0)
    end

    it "deletes the passkey and responds with 204" do
      authenticate_next_request_as(user)
      delete account_passkey_path(passkey), as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.passkeys.reload).to be_empty
    end
  end
end
