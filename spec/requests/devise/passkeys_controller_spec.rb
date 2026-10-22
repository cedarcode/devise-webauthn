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
        post account_passkey_registration_options_path # To set the challenge in session
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

      context "when the credential cannot be parsed" do
        it "clears the challenge and redirects" do
          post account_passkeys_path, params: { public_key_credential: "{}", name: "My Passkey" }

          expect(response).to redirect_to(new_account_passkey_path)
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

    context "with a JSON request" do
      let(:challenge) do
        post account_passkey_registration_options_path, as: :json
        response.parsed_body["challenge"]
      end

      let(:public_key_credential) { client.create(challenge: challenge, user_verified: true) }

      it "creates a passkey and responds with 201 and no body" do
        sign_in user, scope: :account

        expect do
          post account_passkeys_path, params: { name: "My phone", public_key_credential: public_key_credential },
                                      as: :json
        end.to change(user.passkeys, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.body).to be_empty
      end

      context "without a session" do
        include_context "with a JSON client without a session"

        let(:challenge) do
          without_session_json_post account_passkey_registration_options_path, authenticated_as: user
          response.parsed_body["challenge"]
        end

        it "creates a passkey and responds with 201 and no body" do
          expect do
            without_session_json_post account_passkeys_path, name: "My phone",
                                                             public_key_credential: public_key_credential,
                                                             authenticated_as: user
          end.to change(user.passkeys, :count).by(1)

          expect(response).to have_http_status(:created)
          expect(response.body).to be_empty
        end

        it "responds with 422 and an error message when verification fails" do
          credential = client.create(challenge: WebAuthn.configuration.encoder.encode("wrong"), user_verified: true)

          without_session_json_post account_passkeys_path, name: "My phone", public_key_credential: credential,
                                                           authenticated_as: user

          expect(response).to have_http_status(422)
          expect(response.parsed_body["errors"])
            .to eq("base" => [I18n.t("devise.failure.passkey_verification_failed")])
        end

        it "responds with 422 and an error message when the credential has no response" do
          without_session_json_post account_passkeys_path, name: "My phone",
                                                           public_key_credential: { type: "public-key" },
                                                           authenticated_as: user

          expect(response).to have_http_status(422)
          expect(response.parsed_body["errors"])
            .to eq("base" => [I18n.t("devise.failure.passkey_verification_failed")])
        end

        it "responds with 422 when the credential is missing" do
          without_session_json_post account_passkeys_path, name: "My phone", authenticated_as: user

          expect(response).to have_http_status(422)
        end

        it "creates a passkey and responds with 201 when the app does not route the HTML pages" do
          without_html_pages_routed :after_update_path

          without_session_json_post account_passkeys_path, name: "My phone",
                                                           public_key_credential: public_key_credential,
                                                           authenticated_as: user

          expect(response).to have_http_status(:created)
        end

        it "responds with 422 and an error message when the app does not route the HTML pages" do
          without_html_pages_routed :after_update_path

          without_session_json_post account_passkeys_path, name: "My phone", authenticated_as: user

          expect(response).to have_http_status(422)
          expect(response.parsed_body["errors"])
            .to eq("base" => [I18n.t("devise.failure.passkey_verification_failed")])
        end
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
          expect(flash[:notice]).to eq I18n.t("devise.passkeys.passkey_deleted")
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

    context "with a JSON request" do
      let!(:passkey) do
        user.passkeys.create!(external_id: "external-id", name: "My Passkey", public_key: "public-key", sign_count: 0)
      end

      it "deletes the passkey and responds with 204" do
        sign_in user, scope: :account
        delete account_passkey_path(passkey), as: :json

        expect(response).to have_http_status(:no_content)
        expect(user.passkeys.reload).to be_empty
      end

      context "without a session" do
        include_context "with a JSON client without a session"

        it "deletes the passkey and responds with 204" do
          without_session_json_delete account_passkey_path(passkey), authenticated_as: user

          expect(response).to have_http_status(:no_content)
          expect(user.passkeys.reload).to be_empty
        end

        it "deletes the passkey and responds with 204 when the app does not route the HTML pages" do
          without_html_pages_routed :after_update_path

          without_session_json_delete account_passkey_path(passkey), authenticated_as: user

          expect(response).to have_http_status(:no_content)
          expect(user.passkeys.reload).to be_empty
        end
      end
    end
  end
end
