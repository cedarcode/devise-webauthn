# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::TwoFactorAuthenticationsController, type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }

  describe "GET #new" do
    context "when user is authenticated" do
      before do
        sign_in user, scope: :user
      end

      it "redirects to root path" do
        get new_user_two_factor_authentication_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is not authenticated" do
      context "when user has not initiated sign in" do
        it "redirects to the sign-in page" do
          get new_user_two_factor_authentication_path

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to eq "Sign in was not initiated."
        end
      end

      context "when user has initiated sign in" do
        before do
          user.passkeys.create!(
            external_id: "external-id",
            name: "My Passkey",
            public_key: "public-key",
            sign_count: 0
          )

          post user_session_path, params: {
            user: {
              email: user.email,
              password: "password123"
            }
          }
        end

        it "renders the new template" do
          get new_user_two_factor_authentication_path

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
