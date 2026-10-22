# frozen_string_literal: true

require "webauthn/fake_client"

RSpec.describe "Passkey authentication flow", type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  let!(:passkey) do
    user.update!(webauthn_id: WebAuthn.generate_user_id)
    credential = WebAuthn::Credential.from_create(client.create(challenge: random_challenge))
    user.passkeys.create!(external_id: credential.id, name: "My Passkey", public_key: credential.public_key,
                          sign_count: credential.sign_count)
  end

  let(:challenge) do
    post account_passkey_authentication_options_path, as: :json
    response.parsed_body["challenge"]
  end

  let(:public_key_credential) { generate_assertion(challenge) }

  def generate_assertion(challenge)
    client.get(challenge: challenge, allow_credentials: [passkey.external_id], user_verified: true,
               user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id))
  end

  it "signs in with the credential sent as a JSON object" do
    post account_session_path, params: { public_key_credential: public_key_credential }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["email"]).to eq(user.email)
  end

  it "rejects a challenge that was already used" do
    post account_session_path, params: { public_key_credential: public_key_credential }, as: :json

    post account_session_path, params: { public_key_credential: generate_assertion(challenge) }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a challenge the server never issued" do
    post account_session_path, params: { public_key_credential: generate_assertion(random_challenge) }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a malformed credential" do
    post account_session_path, params: { public_key_credential: "not json" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
