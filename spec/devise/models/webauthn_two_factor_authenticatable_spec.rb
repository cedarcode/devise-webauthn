# frozen_string_literal: true

RSpec.describe Devise::Models::WebauthnTwoFactorAuthenticatable, type: :model do
  describe "#ensure_webauthn_id!" do
    it "does not generate a webauthn_id on create" do
      user = Account.create!(email: "user@example.com", password: "password", password_confirmation: "password")
      expect(user.webauthn_id).to be_nil
    end

    it "generates and persists a webauthn_id when missing" do
      user = Account.create!(email: "user@example.com", password: "password", password_confirmation: "password")

      webauthn_id = user.ensure_webauthn_id!

      expect(webauthn_id).to be_present
      expect(user.reload.webauthn_id).to eq(webauthn_id)
    end

    it "does not replace an existing webauthn_id" do
      user = Account.create!(email: "user@example.com", password: "password", password_confirmation: "password",
                             webauthn_id: "custom")

      expect(user.ensure_webauthn_id!).to eq("custom")
      expect(user.reload.webauthn_id).to eq("custom")
    end
  end

  describe "associations" do
    it "has many webauthn credentials" do
      user = Account.create!(email: "user2@example.com", password: "password", password_confirmation: "password")
      passkey = WebauthnCredential.create!(account: user,
                                           external_id: "ext1",
                                           public_key: "pk1",
                                           name: "My Passkey",
                                           sign_count: 0,
                                           authentication_factor: :first_factor)
      security_key = WebauthnCredential.create!(account: user,
                                                external_id: "ext2",
                                                public_key: "pk2",
                                                name: "My Passkey",
                                                sign_count: 0,
                                                authentication_factor: :second_factor)
      expect(user.webauthn_credentials).to contain_exactly(passkey, security_key)
    end

    it "has many second factor webauthn credentials" do
      user = Account.create!(email: "user2@example.com", password: "password", password_confirmation: "password")
      WebauthnCredential.create!(account: user,
                                 external_id: "ext1",
                                 public_key: "pk1",
                                 name: "My Passkey",
                                 sign_count: 0,
                                 authentication_factor: :first_factor)
      security_key = WebauthnCredential.create!(account: user,
                                                external_id: "ext2",
                                                public_key: "pk2",
                                                name: "My Passkey",
                                                sign_count: 0,
                                                authentication_factor: :second_factor)
      expect(user.second_factor_webauthn_credentials).to contain_exactly(security_key)
    end
  end

  describe "validations" do
    it "validates uniqueness of webauthn_id" do
      existing = Account.create!(email: "existing@example.com", password: "password",
                                 password_confirmation: "password", webauthn_id: WebAuthn.generate_user_id)
      user = Account.new(email: "new@example.com", webauthn_id: existing.webauthn_id)
      expect(user).not_to be_valid
      expect(user.errors[:webauthn_id]).to include("has already been taken")
    end
  end
end
