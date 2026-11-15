# frozen_string_literal: true

require "webauthn/fake_client"

RSpec.describe "API client flows", type: :request do
  let(:password) { "password123" }
  let(:user) { Account.create!(email: "test@example.com", password: password, webauthn_id: WebAuthn.generate_user_id) }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  def register_credential(credentials, **attributes)
    credential = WebAuthn::Credential.from_create(client.create(challenge: random_challenge))
    credentials.create!(external_id: credential.id, name: "My credential", public_key: credential.public_key,
                        sign_count: credential.sign_count, **attributes)
  end

  def registration_challenge(options_path)
    authenticate_next_request_as(user)
    post options_path, as: :json
    response.parsed_body["challenge"]
  end

  it "signs in with a passkey" do
    passkey = register_credential(user.passkeys)
    post account_passkey_authentication_options_path, as: :json
    assertion = client.get(challenge: response.parsed_body["challenge"], allow_credentials: [passkey.external_id],
                           user_verified: true, user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id))

    post account_session_path, params: { public_key_credential: assertion }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["email"]).to eq(user.email)
  end

  it "signs in with a password, a two-factor token and a security key" do
    security_key = register_credential(user.second_factor_webauthn_credentials)
    post account_session_path, params: { account: { email: user.email, password: password } }, as: :json
    expect(response).to have_http_status(:unauthorized)
    token = response.parsed_body["two_factor_token"]

    post account_security_key_authentication_options_path, params: { two_factor_token: token }, as: :json
    assertion = client.get(challenge: response.parsed_body["challenge"], allow_credentials: [security_key.external_id])
    post account_two_factor_authentication_path,
         params: { two_factor_token: token, public_key_credential: assertion }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["email"]).to eq(user.email)
  end

  it "registers a passkey" do
    credential = client.create(challenge: registration_challenge(account_passkey_registration_options_path),
                               user_verified: true)
    authenticate_next_request_as(user)

    expect do
      post account_passkeys_path, params: { name: "My phone", public_key_credential: credential }, as: :json
    end.to change(user.passkeys, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it "registers a security key" do
    challenge = registration_challenge(account_security_key_registration_options_path)
    authenticate_next_request_as(user)

    expect do
      post account_second_factor_webauthn_credentials_path,
           params: { name: "My key", public_key_credential: client.create(challenge: challenge) }, as: :json
    end.to change(user.second_factor_webauthn_credentials, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it "deletes a passkey" do
    passkey = register_credential(user.passkeys)
    authenticate_next_request_as(user)

    delete account_passkey_path(passkey), as: :json

    expect(response).to have_http_status(:no_content)
  end

  it "promotes a security key to a passkey" do
    security_key = register_credential(user.second_factor_webauthn_credentials, discoverable: true,
                                                                                uv_initialized: true)
    authenticate_next_request_as(user)

    patch account_second_factor_webauthn_credential_path(security_key), as: :json

    expect(response).to have_http_status(:no_content)
    expect(security_key.reload).to be_first_factor
  end

  it "deletes a security key" do
    security_key = register_credential(user.second_factor_webauthn_credentials)
    authenticate_next_request_as(user)

    delete account_second_factor_webauthn_credential_path(security_key), as: :json

    expect(response).to have_http_status(:no_content)
  end
end
