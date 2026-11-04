# frozen_string_literal: true

require "webauthn/fake_client"

RSpec.describe Devise::SecondFactorWebauthnCredentialsController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  let(:security_key) do
    user.second_factor_webauthn_credentials.create!(external_id: "external-id", name: "My Key",
                                                    public_key: "public-key", sign_count: 0,
                                                    authentication_factor: "second_factor")
  end

  describe "POST #create" do
    let(:challenge) do
      authenticate_next_request_as(user)
      post account_security_key_registration_options_path, as: :json
      response.parsed_body["challenge"]
    end

    let(:public_key_credential) { client.create(challenge: challenge) }

    def create_security_key(params)
      authenticate_next_request_as(user)
      post account_second_factor_webauthn_credentials_path, params: { name: "My key" }.merge(params), as: :json
    end

    it "creates a security key and responds with 201 and no body" do
      expect { create_security_key(public_key_credential: public_key_credential) }
        .to change(user.second_factor_webauthn_credentials, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.body).to be_empty
    end

    it "responds with 422 and an error message when verification fails" do
      create_security_key(public_key_credential: client.create(challenge: random_challenge))

      expect(response).to have_http_status(422)
      expect(response.parsed_body["errors"])
        .to eq("base" => [I18n.t("devise.failure.webauthn_credential_verification_failed")])
    end

    it "responds with 422 when the credential has no response" do
      create_security_key(public_key_credential: { type: "public-key" })

      expect(response).to have_http_status(422)
    end
  end

  describe "PATCH #update" do
    it "promotes the security key and responds with 204" do
      authenticate_next_request_as(user)
      patch account_second_factor_webauthn_credential_path(security_key), as: :json

      expect(response).to have_http_status(:no_content)
      expect(security_key.reload).to be_first_factor
    end
  end

  describe "DELETE #destroy" do
    it "deletes the security key and responds with 204" do
      authenticate_next_request_as(user)
      delete account_second_factor_webauthn_credential_path(security_key), as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.second_factor_webauthn_credentials.reload).to be_empty
    end
  end
end
