# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::SecurityKey::AuthenticationOptionsController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }

  describe "GET #index" do
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
      get account_security_key_authentication_options_path

      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body).to include("challenge")

      expect(session[:two_factor_authentication_challenge]).to eq(body["challenge"])
    end
  end
end
