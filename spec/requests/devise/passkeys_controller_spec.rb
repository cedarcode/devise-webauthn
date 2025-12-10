# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe Devise::PasskeysController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  describe "GET #new" do
    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        get new_account_passkey_path
        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user, scope: :account
      end

      it "renders the new template" do
        get new_account_passkey_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST #create" do
    context "when user is authenticated" do
      before do
        sign_in user, scope: :account
        get options_for_create_account_passkeys_path # To set the challenge in session
      end

      context "with valid parameters" do
        let(:credential) do
          client.create(
            challenge: session[:webauthn_challenge],
            user_verified: true
          )
        end

        it "creates a new passkey and redirects" do
          assert_difference("user.passkeys.count", 1) do
            post account_passkeys_path, params: {
              public_key_credential: credential.to_json,
              name: "My Passkey"
            }
          end

          expect(response).to redirect_to(new_account_passkey_path)
          expect(flash[:notice]).to eq I18n.t("devise.passkeys.passkey_created")
          expect(session[:webauthn_challenge]).to be_nil
        end
      end

      context "with invalid credential" do
        let(:invalid_credential) do
          client.create(
            challenge: session[:webauthn_challenge],
            user_verified: false
          )
        end

        it "does not create a new passkey and redirects" do
          assert_difference("user.passkeys.count", 0) do
            post account_passkeys_path, params: {
              public_key_credential: invalid_credential.to_json,
              name: "My Passkey"
            }
          end

          expect(response).to redirect_to(new_account_passkey_path)
          expect(flash[:alert]).to eq I18n.t("devise.failure.passkey_verification_failed")
          expect(session[:webauthn_challenge]).to be_nil
        end
      end
    end

    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        post account_passkeys_path, params: { public_key_credential: "{}" }
        expect(response).to redirect_to(new_account_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user is authenticated" do
      let!(:passkey) do
        user.passkeys.create!(
          external_id: "external-id",
          name: "My Passkey",
          public_key: "public-key",
          sign_count: 0
        )
      end

      before do
        sign_in user, scope: :account
      end

      it "deletes the passkey and redirects" do
        assert_difference("user.passkeys.count", -1) do
          delete account_passkey_path(passkey)
          expect(response).to redirect_to(new_account_passkey_path)
        end
      end
    end

    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        delete account_passkey_path(1)
        expect(response).to redirect_to(new_account_session_path)
      end
    end
  end
end
