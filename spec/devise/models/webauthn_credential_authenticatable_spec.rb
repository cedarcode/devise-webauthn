# frozen_string_literal: true

RSpec.describe Devise::Models::WebauthnCredentialAuthenticatable, type: :model do
  let(:user) { Account.create!(email: "user@example.com", password: "password", password_confirmation: "password") }

  # Devise's common setup for signing in with a username or an email.
  let(:account_with_login_key) do
    Class.new(Account) do
      attr_accessor :login

      def self.name
        "Account"
      end

      def self.authentication_keys
        [:login]
      end
    end
  end

  describe "#webauthn_user_name" do
    it "is the first authentication key" do
      expect(user.webauthn_user_name).to eq("user@example.com")
    end

    it "reads authentication keys given as a hash" do
      allow(Account).to receive(:authentication_keys).and_return({ email: true })

      expect(user.webauthn_user_name).to eq("user@example.com")
    end

    it "falls back to the email when the authentication key is virtual" do
      account = account_with_login_key.find(user.id)

      expect(account.webauthn_user_name).to eq("user@example.com")
    end

    it "falls back to the record id when there is no email" do
      account = account_with_login_key.find(user.id)
      account.email = ""

      expect(account.webauthn_user_name).to eq(user.id.to_s)
    end
  end

  describe "#webauthn_display_name" do
    it "defaults to the user name" do
      account = account_with_login_key.find(user.id)

      expect(account.webauthn_display_name).to eq("user@example.com")
    end
  end
end
