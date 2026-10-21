# frozen_string_literal: true

require "webauthn/fake_client"

RSpec.describe "Two-Factor authentication flow", type: :request do
  let(:password) { "password123" }
  let(:user) { Account.create!(email: "test@example.com", password: password) }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  let!(:security_key) do
    user.update!(webauthn_id: WebAuthn.generate_user_id)
    credential = WebAuthn::Credential.from_create(client.create(challenge: random_challenge))
    user.second_factor_webauthn_credentials.create!(external_id: credential.id, name: "Test Security Key",
                                                    public_key: credential.public_key,
                                                    sign_count: credential.sign_count)
  end

  def request_two_factor_token
    post account_session_path, params: { account: { email: user.email, password: password } }, as: :json
    response.parsed_body["two_factor_token"]
  end

  def security_key_assertion(token)
    post account_security_key_authentication_options_path, params: { two_factor_token: token }, as: :json
    client.get(challenge: response.parsed_body["challenge"], allow_credentials: [security_key.external_id])
  end

  it "responds to the password step with 401 and a two-factor token" do
    post account_session_path, params: { account: { email: user.email, password: password } }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("error" => I18n.t("devise.failure.two_factor_required"),
                                            "two_factor_token" => be_present)
  end

  it "signs in with the two-factor token and a security key" do
    token = request_two_factor_token
    assertion = security_key_assertion(token)

    post account_two_factor_authentication_path,
         params: { two_factor_token: token, public_key_credential: assertion.to_json }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["email"]).to eq(user.email)
  end

  it "responds to the options step with 401 when the two-factor token is invalid" do
    token = request_two_factor_token

    post account_security_key_authentication_options_path, params: { two_factor_token: "#{token}x" }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body["error"]).to eq(I18n.t("devise.failure.sign_in_not_initiated"))
  end

  it "ignores a two-factor token in the query string" do
    token = request_two_factor_token

    post "#{account_security_key_authentication_options_path}?two_factor_token=#{CGI.escape(token)}", as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body["error"]).to eq(I18n.t("devise.failure.sign_in_not_initiated"))
  end

  it "filters the two-factor token from the logged parameters" do
    post account_security_key_authentication_options_path, params: { two_factor_token: request_two_factor_token },
                                                           as: :json

    expect(request.filtered_parameters["two_factor_token"]).to eq("[FILTERED]")
  end

  it "rejects a tampered two-factor token" do
    token = request_two_factor_token
    assertion = security_key_assertion(token)

    post account_two_factor_authentication_path,
         params: { two_factor_token: "#{token}x", public_key_credential: assertion.to_json }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body["error"]).to eq(I18n.t("devise.failure.sign_in_not_initiated"))
  end
end
