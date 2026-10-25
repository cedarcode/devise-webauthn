# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::SecurityKeyUpgradeOptionsController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }

  describe "POST #create" do
    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        post account_security_key_upgrade_options_path
        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user, scope: :account
      end

      it "stores the challenge in session and returns it as json" do
        post account_security_key_upgrade_options_path

        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        expect(json["challenge"]).to be_present
        expect(session[:security_key_upgrade_challenge]).to eq(json["challenge"])
      end

      it "asks for the same credential as passkey sign-in: discoverable and user verified" do
        post account_security_key_upgrade_options_path

        json = response.parsed_body
        expect(json["allowCredentials"]).to be_blank
        expect(json["userVerification"]).to eq("required")
      end

      it "does not start a passkey sign-in" do
        post account_security_key_upgrade_options_path

        expect(session[:authentication_challenge]).to be_nil
      end
    end
  end

  it_behaves_like "a controller that loads under an ActionController::API parent"
end
