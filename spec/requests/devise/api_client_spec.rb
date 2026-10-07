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

    Devise::Webauthn.challenge_store = :cache
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

  def api_patch(path)
    reset!
    patch path, headers: { "ACCEPT" => "application/json" }
  end

  def api_delete(path)
    reset!
    delete path, headers: { "ACCEPT" => "application/json" }
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

  describe "passkey registration" do
    def request_registration_challenge
      sign_in user, scope: :account
      api_post account_passkey_registration_options_path
      response.parsed_body["challenge"]
    end

    it "creates a passkey and responds with 201" do
      credential = client.create(challenge: request_registration_challenge, user_verified: true)

      sign_in user, scope: :account
      expect do
        api_post account_passkeys_path, name: "My phone", public_key_credential: credential
      end.to change(user.passkeys, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["id"]).to eq(user.passkeys.last.id)
    end

    it "responds with 422 and an error message when verification fails" do
      request_registration_challenge
      credential = client.create(challenge: WebAuthn.configuration.encoder.encode("wrong"), user_verified: true)

      sign_in user, scope: :account
      api_post account_passkeys_path, name: "My phone", public_key_credential: credential

      expect(response).to have_http_status(422)
      expect(response.parsed_body["errors"]).to eq("base" => [I18n.t("devise.failure.passkey_verification_failed")])
    end

    it "deletes a passkey and responds with 204" do
      passkey = create_credential_for(user, :first_factor)

      sign_in user, scope: :account
      api_delete account_passkey_path(passkey)

      expect(response).to have_http_status(:no_content)
      expect(user.passkeys).to be_empty
    end
  end

  describe "security key registration" do
    def request_registration_challenge
      sign_in user, scope: :account
      api_post account_security_key_registration_options_path
      response.parsed_body["challenge"]
    end

    it "creates a security key and responds with 201" do
      credential = client.create(challenge: request_registration_challenge)

      sign_in user, scope: :account
      expect do
        api_post account_second_factor_webauthn_credentials_path, name: "My key", public_key_credential: credential
      end.to change(user.second_factor_webauthn_credentials, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["id"]).to eq(user.second_factor_webauthn_credentials.last.id)
    end

    it "responds with 422 and an error message when verification fails" do
      request_registration_challenge
      credential = client.create(challenge: WebAuthn.configuration.encoder.encode("wrong"))

      sign_in user, scope: :account
      api_post account_second_factor_webauthn_credentials_path, name: "My key", public_key_credential: credential

      expect(response).to have_http_status(422)
      expect(response.parsed_body["errors"])
        .to eq("base" => [I18n.t("devise.failure.webauthn_credential_verification_failed")])
    end

    it "promotes a security key to a passkey and responds with 204" do
      security_key = create_credential_for(user, :second_factor)

      sign_in user, scope: :account
      api_patch account_second_factor_webauthn_credential_path(security_key)

      expect(response).to have_http_status(:no_content)
      expect(security_key.reload).to be_first_factor
    end

    it "deletes a security key and responds with 204" do
      security_key = create_credential_for(user, :second_factor)

      sign_in user, scope: :account
      api_delete account_second_factor_webauthn_credential_path(security_key)

      expect(response).to have_http_status(:no_content)
      expect(user.second_factor_webauthn_credentials).to be_empty
    end
  end

  describe "options controllers under an ActionController::API parent" do
    # RSpec restores each hidden controller by redefining its constant.
    around { |example| silence_warnings { example.run } }

    %w[
      PasskeyAuthenticationOptionsController
      PasskeyRegistrationOptionsController
      SecurityKeyAuthenticationOptionsController
      SecurityKeyRegistrationOptionsController
    ].each do |controller|
      it "loads Devise::#{controller}" do
        # Hiding autoloads the real controller, so it must happen before DeviseController is stubbed.
        hide_const("Devise::#{controller}")
        stub_const("DeviseController", Class.new(ActionController::API))
        path = Devise::Webauthn::Engine.root.join("app/controllers/devise/#{controller.underscore}.rb")

        expect { load path.to_s }.not_to raise_error
      end
    end
  end

  describe "two-factor sign-in" do
    let!(:security_key) { create_credential_for(user, :second_factor) }

    def request_two_factor_token
      api_post account_session_path, account: { email: user.email, password: password }
      response.parsed_body["two_factor_token"]
    end

    def security_key_assertion(token)
      api_post account_security_key_authentication_options_path, two_factor_token: token
      client.get(challenge: response.parsed_body["challenge"], allow_credentials: [security_key.external_id])
    end

    it "responds to the password step with 401 and a two-factor token" do
      api_post account_session_path, account: { email: user.email, password: password }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include("error" => I18n.t("devise.failure.two_factor_required"),
                                              "two_factor_token" => be_present)
    end

    it "signs in with the two-factor token and a security key and does not store the user in the session" do
      token = request_two_factor_token
      assertion = security_key_assertion(token)

      api_post account_two_factor_authentication_path, two_factor_token: token, public_key_credential: assertion

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["email"]).to eq(user.email)
      expect(session["warden.user.account.key"]).to be_nil
    end

    it "rejects a tampered two-factor token" do
      token = request_two_factor_token
      assertion = security_key_assertion(token)

      api_post account_two_factor_authentication_path, two_factor_token: "#{token}x", public_key_credential: assertion

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq(I18n.t("devise.failure.sign_in_not_initiated"))
    end
  end

  describe "passkey sign-in with the signed challenge store" do
    let!(:passkey) { create_credential_for(user, :first_factor) }

    before { Devise::Webauthn.challenge_store = :signed }

    def passkey_assertion(challenge)
      client.get(challenge: challenge, allow_credentials: [passkey.external_id], user_verified: true,
                 user_handle: WebAuthn.configuration.encoder.decode(user.webauthn_id))
    end

    it "signs in with a challenge the server signed, without keeping any state" do
      api_post account_passkey_authentication_options_path
      challenge = response.parsed_body["challenge"]

      api_post account_session_path, public_key_credential: passkey_assertion(challenge)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["email"]).to eq(user.email)
    end

    it "rejects a challenge the server never signed" do
      challenge = WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32))

      api_post account_session_path, public_key_credential: passkey_assertion(challenge)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
