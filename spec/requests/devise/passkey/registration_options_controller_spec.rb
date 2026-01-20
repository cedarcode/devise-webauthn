# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Passkey::RegistrationOptionsController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }

  describe "GET #index" do
    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        get account_passkey_registration_options_path
        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user, scope: :account
      end

      it "returns webauthn create options as json and stores the challenge in session" do
        get account_passkey_registration_options_path

        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        expect(json["challenge"]).to be_present

        expect(session[:webauthn_challenge]).to eq(json["challenge"])
      end

      it "generates a new challenge on each request" do
        get account_passkey_registration_options_path
        first_challenge = session[:webauthn_challenge]

        get account_passkey_registration_options_path
        second_challenge = session[:webauthn_challenge]

        expect(first_challenge).to be_present
        expect(second_challenge).to be_present
        expect(second_challenge).not_to eq(first_challenge)
      end
    end
  end
end
