# frozen_string_literal: true

require "spec_helper"

RSpec.describe Devise::Passkey::AuthenticationOptionsController, type: :request do
  describe "GET #index" do
    it "stores the challenge in session and returns it as json" do
      get account_passkey_authentication_options_path

      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["challenge"]).to be_present
      expect(session[:authentication_challenge]).to eq(json["challenge"])
    end

    it "generates a new challenge on each request" do
      get account_passkey_authentication_options_path
      first_challenge = session[:authentication_challenge]

      get account_passkey_authentication_options_path
      second_challenge = session[:authentication_challenge]

      expect(first_challenge).to be_present
      expect(second_challenge).not_to eq(first_challenge)
    end
  end
end
