# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe "Two-Factor authentication flow", type: :request do
  let(:password) { "password123" }
  let(:user) { Account.create!(email: "test@example.com", password: password) }
  let(:origin) { WebAuthn.configuration.allowed_origins.first }
  let(:client) { WebAuthn::FakeClient.new(origin) }

  def create_security_key_for(account, fake_client)
    creation_options = WebAuthn::Credential.options_for_create(
      user: { id: account.webauthn_id, name: account.email }
    )

    raw_credential = fake_client.create(challenge: creation_options.challenge)
    webauthn_credential = WebAuthn::Credential.from_create(raw_credential)

    account.second_factor_webauthn_credentials.create!(
      external_id: webauthn_credential.id,
      name: "Test Security Key",
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count
    )
  end

  def generate_assertion(fake_client, challenge:, credential:)
    fake_client.get(
      challenge: challenge,
      allow_credentials: [credential.external_id]
    )
  end

  describe "sign-in with 2FA enabled" do
    let!(:security_key) { create_security_key_for(user, client) }

    it "completes authentication with valid password and valid credential" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).to redirect_to(new_account_two_factor_authentication_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to eq(I18n.t("devise.failure.two_factor_required"))
      expect(session[:current_authentication_resource_id]).to eq(user.id)
      expect(session[:two_factor_authentication_challenge]).not_to be_nil

      assertion = generate_assertion(
        client,
        challenge: session[:two_factor_authentication_challenge],
        credential: security_key
      )

      expect do
        post account_two_factor_authentication_path, params: {
          public_key_credential: assertion.to_json
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq(I18n.t("devise.sessions.signed_in"))
        expect(controller.current_account).to eq(user)
        expect(session[:two_factor_authentication_challenge]).to be_nil
        expect(session[:current_authentication_resource_id]).to be_nil
      end.to change { security_key.reload.sign_count }.by(1)
    end

    it "rejects sign-in with invalid password" do
      post account_session_path, params: { account: { email: user.email, password: "wrong password" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:current_authentication_resource_id]).to be_nil
      expect(session[:two_factor_authentication_challenge]).to be_nil
    end

    it "rejects 2FA with non-existent credential" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).to redirect_to(new_account_two_factor_authentication_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to include(I18n.t("devise.failure.two_factor_required"))
      expect(session[:current_authentication_resource_id]).to eq(user.id)
      expect(session[:two_factor_authentication_challenge]).not_to be_nil

      assertion = generate_assertion(
        client,
        challenge: session[:two_factor_authentication_challenge],
        credential: security_key
      )
      security_key.destroy!

      post account_two_factor_authentication_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Use security key")
      expect(flash[:alert]).to eq(I18n.t("devise.failure.webauthn_credential_not_found"))
      expect(controller.current_account).to be_nil
    end

    it "rejects 2FA with invalid challenge" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).to redirect_to(new_account_two_factor_authentication_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to include(I18n.t("devise.failure.two_factor_required"))
      expect(session[:current_authentication_resource_id]).to eq(user.id)
      expect(session[:two_factor_authentication_challenge]).not_to be_nil

      assertion = client.get(
        challenge: WebAuthn.configuration.encoder.encode("invalid_challenge"),
        allow_credentials: [security_key.external_id]
      )

      post account_two_factor_authentication_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Use security key")
      expect(flash[:alert]).to eq(I18n.t("devise.failure.webauthn_credential_verification_failed"))
      expect(controller.current_account).to be_nil
    end

    it "rejects 2FA with credential from different user" do
      other_user = Account.create!(email: "other@example.com", password: password)
      other_credential = create_security_key_for(other_user, client)

      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).to redirect_to(new_account_two_factor_authentication_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to include(I18n.t("devise.failure.two_factor_required"))
      expect(session[:current_authentication_resource_id]).to eq(user.id)
      expect(session[:two_factor_authentication_challenge]).not_to be_nil

      assertion = client.get(
        challenge: session[:two_factor_authentication_challenge],
        allow_credentials: [other_credential.external_id]
      )

      post account_two_factor_authentication_path, params: {
        public_key_credential: assertion.to_json
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Use security key")
      expect(flash[:alert]).to eq(I18n.t("devise.failure.webauthn_credential_not_found"))
      expect(controller.current_account).to be_nil
    end

    it "re-renders 2FA page when credential param is missing" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).to redirect_to(new_account_two_factor_authentication_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to include(I18n.t("devise.failure.two_factor_required"))
      expect(session[:current_authentication_resource_id]).to eq(user.id)
      expect(session[:two_factor_authentication_challenge]).not_to be_nil

      post account_two_factor_authentication_path, params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Use security key")
      expect(flash[:alert]).to match(/Invalid email or password/i) # TODO: CHANGE THIS
      expect(controller.current_account).to be_nil
    end
  end

  describe "sign-in with 2FA disabled" do
    it "authenticates user directly with valid password" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).to redirect_to(root_path)
      expect(controller.current_account).to eq(user)
    end

    it "does not redirect to 2FA page" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(response).not_to redirect_to(new_account_two_factor_authentication_path)
    end

    it "does not set 2FA session state" do
      post account_session_path, params: { account: { email: user.email, password: password } }

      expect(session[:current_authentication_resource_id]).to be_nil
    end
  end

  describe "2FA page access control" do
    context "when already authenticated" do
      before { sign_in user }

      it "redirects away from 2FA page" do
        get new_account_two_factor_authentication_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when sign-in was not initiated" do
      it "redirects to sign-in page with flash message" do
        get new_account_two_factor_authentication_path

        expect(response).to redirect_to(new_account_session_path)
        expect(flash[:alert]).to eq(I18n.t("devise.failure.sign_in_not_initiated"))
      end
    end
  end
end
