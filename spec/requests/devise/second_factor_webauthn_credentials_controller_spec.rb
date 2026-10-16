# frozen_string_literal: true

require "spec_helper"
require "webauthn/fake_client"

RSpec.describe Devise::SecondFactorWebauthnCredentialsController, type: :request do
  let(:user) { Account.create!(email: "test@example.com", password: "password123") }
  let(:client) { WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first) }

  describe "GET #new" do
    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        get new_account_second_factor_webauthn_credential_path

        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "renders the new template" do
        get new_account_second_factor_webauthn_credential_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST #create" do
    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        post account_second_factor_webauthn_credentials_path

        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
        post account_security_key_registration_options_path # To set the challenge in session
      end

      context "with valid parameters" do
        let(:credential) do
          client.create(
            challenge: session[:webauthn_challenge],
            user_verified: false
          )
        end

        it "creates a new security key and redirects" do
          assert_difference("user.second_factor_webauthn_credentials.count", 1) do
            post account_second_factor_webauthn_credentials_path, params: {
              public_key_credential: credential.to_json,
              name: "My Security Key"
            }
          end

          expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
          expect(flash[:notice]).to eq "Security Key created successfully."
          expect(session[:webauthn_challenge]).to be_nil
        end
      end

      context "with invalid credential" do
        let(:invalid_credential) do
          client.create(
            challenge: session[:webauthn_challenge],
            user_present: false
          )
        end

        it "does not create a new security key and redirects" do
          assert_difference("user.second_factor_webauthn_credentials.count", 0) do
            post account_second_factor_webauthn_credentials_path, params: {
              public_key_credential: invalid_credential.to_json,
              name: "My Security Key"
            }
          end

          expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
          expect(flash[:alert]).to eq "Webauthn credential verification failed."
          expect(session[:webauthn_challenge]).to be_nil
        end
      end

      context "when the credential cannot be parsed" do
        it "clears the challenge and redirects" do
          post account_second_factor_webauthn_credentials_path, params: { public_key_credential: "{}", name: "Key" }

          expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
          expect(session[:webauthn_challenge]).to be_nil
        end
      end
    end

    context "with a JSON request from a client without a session" do
      include_context "with a JSON client without a session"

      def request_registration_challenge
        sign_in user, scope: :account
        json_post account_security_key_registration_options_path
        response.parsed_body["challenge"]
      end

      it "creates a security key and responds with 201 and no body" do
        credential = client.create(challenge: request_registration_challenge)

        sign_in user, scope: :account
        expect do
          json_post account_second_factor_webauthn_credentials_path, name: "My key", public_key_credential: credential
        end.to change(user.second_factor_webauthn_credentials, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.body).to be_empty
      end

      it "responds with 422 and an error message when verification fails" do
        credential = client.create(challenge: WebAuthn.configuration.encoder.encode("wrong"))

        sign_in user, scope: :account
        json_post account_second_factor_webauthn_credentials_path, name: "My key", public_key_credential: credential

        expect(response).to have_http_status(422)
        expect(response.parsed_body["errors"])
          .to eq("base" => [I18n.t("devise.failure.webauthn_credential_verification_failed")])
      end

      it "responds with 422 when the credential has no response" do
        sign_in user, scope: :account
        json_post account_second_factor_webauthn_credentials_path, name: "My key",
                                                                   public_key_credential: { type: "public-key" }

        expect(response).to have_http_status(422)
      end
    end
  end

  describe "PATCH #update" do
    let!(:security_key) do
      user.second_factor_webauthn_credentials.create!(
        external_id: "external-id",
        name: "My Security Key",
        public_key: "public-key",
        sign_count: 0,
        authentication_factor: "second_factor"
      )
    end

    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        patch account_second_factor_webauthn_credential_path(security_key)

        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user, scope: :account
      end

      it "promotes the security key, sets a notice and redirects" do
        patch account_second_factor_webauthn_credential_path(security_key)

        expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
        expect(flash[:notice]).to eq I18n.t("devise.second_factor_webauthn_credentials.security_key_promoted")

        expect(security_key.reload.authentication_factor).to eq("first_factor")
      end
    end

    context "with a JSON request from a client without a session" do
      include_context "with a JSON client without a session"

      it "promotes the security key and responds with 204" do
        sign_in user, scope: :account
        json_patch account_second_factor_webauthn_credential_path(security_key)

        expect(response).to have_http_status(:no_content)
        expect(security_key.reload).to be_first_factor
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        delete account_second_factor_webauthn_credential_path(1)

        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      let!(:security_key) do
        user.second_factor_webauthn_credentials.create!(
          external_id: "external-id",
          name: "My Passkey",
          public_key: "public-key",
          sign_count: 0
        )
      end

      before do
        sign_in user, scope: :account
      end

      it "deletes the security key and redirects" do
        assert_difference("user.second_factor_webauthn_credentials.count", -1) do
          delete account_second_factor_webauthn_credential_path(security_key)
          expect(flash[:notice]).to eq I18n.t("devise.second_factor_webauthn_credentials.security_key_deleted")
          expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
        end
      end
    end

    context "with a JSON request from a client without a session" do
      include_context "with a JSON client without a session"

      it "deletes the security key and responds with 204" do
        security_key = user.second_factor_webauthn_credentials.create!(external_id: "external-id", name: "My Key",
                                                                       public_key: "public-key", sign_count: 0)

        sign_in user, scope: :account
        json_delete account_second_factor_webauthn_credential_path(security_key)

        expect(response).to have_http_status(:no_content)
        expect(user.second_factor_webauthn_credentials.reload).to be_empty
      end
    end
  end
end
