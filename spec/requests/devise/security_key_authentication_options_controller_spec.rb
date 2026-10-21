# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::SecurityKeyAuthenticationOptionsController, type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { Account.create!(email: "test@example.com", password: "password123") }

  describe "POST #create" do
    before do
      user.passkeys.create!(
        external_id: "external-id",
        name: "My Passkey",
        public_key: "public-key",
        sign_count: 0
      )

      post account_session_path, params: {
        account: {
          email: user.email,
          password: "password123"
        }
      }
    end

    it "returns authentication options and stores the challenge in the session" do
      post account_security_key_authentication_options_path

      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body).to include("challenge")

      expect(session[:two_factor_authentication_challenge]).to eq(body["challenge"])
    end

    it "responds with 401 when the pending sign-in has expired" do
      travel_to(Devise::Webauthn::TwoFactorToken.expires_in.from_now + 1.second) do
        post account_security_key_authentication_options_path, headers: { "ACCEPT" => "application/json" }
      end

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq(I18n.t("devise.failure.sign_in_not_initiated"))
    end
  end

  it_behaves_like "a controller that loads under an ActionController::API parent"
end
