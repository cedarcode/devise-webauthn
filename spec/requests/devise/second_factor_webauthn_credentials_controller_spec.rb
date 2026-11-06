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

      context "with a blank name" do
        let(:credential) do
          client.create(
            challenge: session[:webauthn_challenge],
            user_verified: false
          )
        end

        it "does not create a new security key and shows the failure alert" do
          assert_difference("user.second_factor_webauthn_credentials.count", 0) do
            post account_second_factor_webauthn_credentials_path, params: {
              public_key_credential: credential.to_json,
              name: "   "
            }
          end

          expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
          expect(flash[:notice]).to be_nil
          expect(flash[:alert]).to eq I18n.t("devise.failure.webauthn_credential_verification_failed")
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

    describe "the credential properties it stores" do
      let(:user_verified) { false }
      let(:extension_results) { { "credProps" => { "rk" => true } } }
      let(:security_key) { user.second_factor_webauthn_credentials.last }

      before do
        sign_in user
        post account_security_key_registration_options_path
        credential = client.create(challenge: session[:webauthn_challenge], user_verified: user_verified)
                           .merge("clientExtensionResults" => extension_results)

        post account_second_factor_webauthn_credentials_path, params: {
          public_key_credential: credential.to_json, name: "My Security Key"
        }
      end

      it "stores the rk that the browser reports as discoverable" do
        expect(security_key.discoverable).to be(true)
      end

      context "when the browser reports rk as false" do
        let(:extension_results) { { "credProps" => { "rk" => false } } }

        it { expect(security_key.discoverable).to be(false) }
      end

      context "when the browser does not report credProps" do
        let(:extension_results) { nil }

        it { expect(security_key.discoverable).to be_nil }
      end

      context "when credProps is malformed" do
        let(:extension_results) { { "credProps" => "unknown" } }

        it { expect(security_key.discoverable).to be_nil }
      end

      context "when rk is not a boolean" do
        let(:extension_results) { { "credProps" => { "rk" => "yes" } } }

        it { expect(security_key.discoverable).to be_nil }
      end

      context "when the key verifies the user" do
        let(:user_verified) { true }

        it { expect(security_key.uv_initialized).to be(true) }
      end

      context "when the key does not verify the user" do
        it { expect(security_key.uv_initialized).to be(false) }
      end
    end

    context "with a JSON request" do
      let(:challenge) do
        post account_security_key_registration_options_path, as: :json
        response.parsed_body["challenge"]
      end

      let(:public_key_credential) { client.create(challenge: challenge) }

      it "creates a security key and responds with 201 and no body" do
        sign_in user, scope: :account

        expect do
          post account_second_factor_webauthn_credentials_path,
               params: { name: "My key", public_key_credential: public_key_credential }, as: :json
        end.to change(user.second_factor_webauthn_credentials, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.body).to be_empty
      end

      it "responds with 422 and the validation errors when the name is blank" do
        sign_in user, scope: :account

        expect do
          post account_second_factor_webauthn_credentials_path,
               params: { name: "", public_key_credential: public_key_credential }, as: :json
        end.not_to change(user.second_factor_webauthn_credentials, :count)

        expect(response).to have_http_status(422)
        expect(response.parsed_body["errors"]).to eq("name" => [I18n.t("errors.messages.blank")])
      end

      context "without a session" do
        include_context "with a JSON client without a session"

        let(:challenge) do
          without_session_json_post account_security_key_registration_options_path, authenticated_as: user
          response.parsed_body["challenge"]
        end

        it "creates a security key and responds with 201 and no body" do
          expect do
            without_session_json_post account_second_factor_webauthn_credentials_path,
                                      name: "My key", public_key_credential: public_key_credential,
                                      authenticated_as: user
          end.to change(user.second_factor_webauthn_credentials, :count).by(1)

          expect(response).to have_http_status(:created)
          expect(response.body).to be_empty
        end

        it "responds with 422 and an error message when verification fails" do
          credential = client.create(challenge: WebAuthn.configuration.encoder.encode("wrong"))

          without_session_json_post account_second_factor_webauthn_credentials_path,
                                    name: "My key", public_key_credential: credential, authenticated_as: user

          expect(response).to have_http_status(422)
          expect(response.parsed_body["errors"])
            .to eq("base" => [I18n.t("devise.failure.webauthn_credential_verification_failed")])
        end

        it "responds with 422 when the credential has no response" do
          without_session_json_post account_second_factor_webauthn_credentials_path,
                                    name: "My key", public_key_credential: { type: "public-key" },
                                    authenticated_as: user

          expect(response).to have_http_status(422)
        end
      end
    end
  end

  describe "PATCH #update" do
    let(:discoverable) { true }
    let(:uv_initialized) { true }
    let!(:security_key) do
      user.second_factor_webauthn_credentials.create!(
        external_id: "external-id",
        name: "My Security Key",
        public_key: "public-key",
        sign_count: 0,
        authentication_factor: "second_factor",
        discoverable: discoverable,
        uv_initialized: uv_initialized
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

      context "when the security key is not discoverable" do
        let(:discoverable) { false }

        it "does not promote it, sets an alert and redirects" do
          patch account_second_factor_webauthn_credential_path(security_key)

          expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
          expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
          expect(security_key.reload).to be_second_factor
        end
      end

      context "when the browser did not report whether the security key is discoverable" do
        let(:discoverable) { nil }

        it "does not promote it" do
          patch account_second_factor_webauthn_credential_path(security_key)

          expect(security_key.reload).to be_second_factor
        end
      end

      context "when the security key did not verify the user when it was added" do
        let(:uv_initialized) { false }

        it "does not promote it" do
          patch account_second_factor_webauthn_credential_path(security_key)

          expect(security_key.reload).to be_second_factor
        end
      end

      context "when the security key was added before uv_initialized existed" do
        let(:uv_initialized) { nil }

        it "does not promote it" do
          patch account_second_factor_webauthn_credential_path(security_key)

          expect(security_key.reload).to be_second_factor
        end
      end
    end

    context "with a JSON request" do
      it "promotes the security key and responds with 204" do
        sign_in user, scope: :account
        patch account_second_factor_webauthn_credential_path(security_key), as: :json

        expect(response).to have_http_status(:no_content)
        expect(security_key.reload).to be_first_factor
      end

      context "when the security key is not discoverable" do
        let(:discoverable) { false }

        it "responds with 422 and an error message" do
          sign_in user, scope: :account
          patch account_second_factor_webauthn_credential_path(security_key), as: :json

          expect(response).to have_http_status(422)
          expect(response.parsed_body["errors"])
            .to eq("base" => [I18n.t("devise.failure.security_key_promotion_failed")])
          expect(security_key.reload).to be_second_factor
        end
      end

      context "without a session" do
        include_context "with a JSON client without a session"

        it "promotes the security key and responds with 204" do
          without_session_json_patch account_second_factor_webauthn_credential_path(security_key),
                                     authenticated_as: user

          expect(response).to have_http_status(:no_content)
          expect(security_key.reload).to be_first_factor
        end
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

    context "with a JSON request" do
      let!(:security_key) do
        user.second_factor_webauthn_credentials.create!(external_id: "external-id", name: "My Key",
                                                        public_key: "public-key", sign_count: 0)
      end

      it "deletes the security key and responds with 204" do
        sign_in user, scope: :account
        delete account_second_factor_webauthn_credential_path(security_key), as: :json

        expect(response).to have_http_status(:no_content)
        expect(user.second_factor_webauthn_credentials.reload).to be_empty
      end

      context "without a session" do
        include_context "with a JSON client without a session"

        it "deletes the security key and responds with 204" do
          without_session_json_delete account_second_factor_webauthn_credential_path(security_key),
                                      authenticated_as: user

          expect(response).to have_http_status(:no_content)
          expect(user.second_factor_webauthn_credentials.reload).to be_empty
        end
      end
    end
  end
end
