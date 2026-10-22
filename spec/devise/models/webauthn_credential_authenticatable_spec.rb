# frozen_string_literal: true

require "devise/models/webauthn_credential_authenticatable"

RSpec.describe Devise::Models::WebauthnCredentialAuthenticatable, type: :model do
  describe "#webauthn_user_name" do
    let(:user) { Account.create!(email: "user@example.com", password: "password", password_confirmation: "password") }

    it "is the first authentication key with a value" do
      expect(user.webauthn_user_name).to eq("user@example.com")
    end

    it "skips an authentication key that is nil" do
      user.singleton_class.attr_accessor :login
      allow(Account).to receive(:authentication_keys).and_return(%i[login email])

      expect(user.webauthn_user_name).to eq("user@example.com")
    end

    it "reads authentication keys given as a hash" do
      allow(Account).to receive(:authentication_keys).and_return({ email: true })

      expect(user.webauthn_user_name).to eq("user@example.com")
    end
  end
end
