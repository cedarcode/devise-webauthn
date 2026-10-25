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
    let(:encoder) { WebAuthn.configuration.encoder }
    let!(:security_key) { create_credential_for(user, :second_factor) }

    def create_credential_for(account, authentication_factor)
      account.update!(webauthn_id: WebAuthn.generate_user_id) if account.webauthn_id.nil?
      challenge = encoder.encode(SecureRandom.random_bytes(32))
      credential = WebAuthn::Credential.from_create(client.create(challenge: challenge))

      account.webauthn_credentials.create!(
        external_id: credential.id,
        name: "My Security Key",
        public_key: credential.public_key,
        sign_count: credential.sign_count,
        authentication_factor: authentication_factor
      )
    end

    # What a discoverable credential with user verification returns to the passkey sign-in options.
    def passkey_assertion(challenge, credential: security_key, user_verified: true,
                          user_handle: encoder.decode(user.webauthn_id))
      client.get(
        challenge: challenge,
        allow_credentials: [credential.external_id],
        user_verified: user_verified,
        user_handle: user_handle
      )
    end

    context "when user is not authenticated" do
      it "redirects to the sign-in page" do
        patch account_second_factor_webauthn_credential_path(security_key)

        expect(response).to redirect_to(new_account_session_path)
      end
    end

    context "when user is authenticated" do
      let(:challenge) { session[:security_key_upgrade_challenge] }

      before do
        sign_in user, scope: :account
        post account_security_key_upgrade_options_path # To set the challenge in session
      end

      it "promotes a security key that signs in as a passkey, sets a notice and redirects" do
        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(challenge).to_json
        }

        expect(security_key.reload).to have_attributes(authentication_factor: "first_factor", sign_count: 1)
        expect(response).to redirect_to(new_account_second_factor_webauthn_credential_path)
        expect(flash[:notice]).to eq I18n.t("devise.second_factor_webauthn_credentials.security_key_promoted")
      end

      it "does not promote the security key without a credential, and clears the challenge" do
        patch account_second_factor_webauthn_credential_path(security_key)

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
        expect(session[:security_key_upgrade_challenge]).to be_nil
      end

      it "does not promote a security key that returns no user handle, like a non-discoverable one" do
        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(challenge, user_handle: nil).to_json
        }

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
      end

      it "does not promote a security key that returns no user handle when the user has no webauthn_id" do
        user.update!(webauthn_id: nil)

        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(challenge, user_handle: nil).to_json
        }

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
      end

      it "does not promote a security key that returns another user handle" do
        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(challenge, user_handle: SecureRandom.random_bytes(64)).to_json
        }

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
      end

      it "does not promote a security key without user verification" do
        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(challenge, user_verified: false).to_json
        }

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
      end

      it "does not promote the security key when another credential answers" do
        passkey = create_credential_for(user, :first_factor)

        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(challenge, credential: passkey).to_json
        }

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
      end

      it "does not promote the security key with a passkey sign-in challenge" do
        post account_passkey_authentication_options_path

        patch account_second_factor_webauthn_credential_path(security_key), params: {
          public_key_credential: passkey_assertion(session[:authentication_challenge]).to_json
        }

        expect(flash[:alert]).to eq I18n.t("devise.failure.security_key_promotion_failed")
        expect(security_key.reload).to be_second_factor
      end
    end

    context "with a JSON request" do
      let(:challenge) do
        post account_security_key_upgrade_options_path, as: :json
        response.parsed_body["challenge"]
      end

      it "promotes the security key and responds with 204" do
        sign_in user, scope: :account
        patch account_second_factor_webauthn_credential_path(security_key),
              params: { public_key_credential: passkey_assertion(challenge) }, as: :json

        expect(response).to have_http_status(:no_content)
        expect(security_key.reload).to be_first_factor
      end

      it "responds with 422 and an error message when the security key cannot sign in as a passkey" do
        sign_in user, scope: :account
        patch account_second_factor_webauthn_credential_path(security_key),
              params: { public_key_credential: passkey_assertion(challenge, user_handle: nil) }, as: :json

        expect(response).to have_http_status(422)
        expect(response.parsed_body["errors"])
          .to eq("base" => [I18n.t("devise.failure.security_key_promotion_failed")])
        expect(security_key.reload).to be_second_factor
      end

      context "without a session" do
        include_context "with a JSON client without a session"

        let(:challenge) do
          without_session_json_post account_security_key_upgrade_options_path, authenticated_as: user
          response.parsed_body["challenge"]
        end

        it "promotes the security key and responds with 204" do
          without_session_json_patch account_second_factor_webauthn_credential_path(security_key),
                                     public_key_credential: passkey_assertion(challenge), authenticated_as: user

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
