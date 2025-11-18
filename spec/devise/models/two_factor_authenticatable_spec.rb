# frozen_string_literal: true

RSpec.describe Devise::Models::TwoFactorAuthenticatable, type: :model do
  describe "webauthn_id initialization" do
    it "generates a webauthn_id on initialize" do
      user = User.new(email: "user@example.com", password: "password", password_confirmation: "password")
      expect(user.webauthn_id).to be_present
    end

    it "keeps existing webauthn_id" do
      user = User.new(email: "user@example.com", password: "password", password_confirmation: "password",
                      webauthn_id: "custom")
      expect(user.webauthn_id).to eq("custom")
    end
  end

  describe "associations" do
    it "has many webauthn credentials" do
      user = User.create!(email: "user2@example.com", password: "password", password_confirmation: "password")
      passkey = WebauthnCredential.create!(user: user,
                                           external_id: "ext1",
                                           public_key: "pk1",
                                           name: "My Passkey",
                                           sign_count: 0,
                                           authentication_factor: :first_factor)
      security_key = WebauthnCredential.create!(user: user,
                                                external_id: "ext2",
                                                public_key: "pk2",
                                                name: "My Passkey",
                                                sign_count: 0,
                                                authentication_factor: :second_factor)
      expect(user.webauthn_credentials).to contain_exactly(passkey, security_key)
    end

    it "has many second factor webauthn credentials" do
      user = User.create!(email: "user2@example.com", password: "password", password_confirmation: "password")
      WebauthnCredential.create!(user: user,
                                 external_id: "ext1",
                                 public_key: "pk1",
                                 name: "My Passkey",
                                 sign_count: 0,
                                 authentication_factor: :first_factor)
      security_key = WebauthnCredential.create!(user: user,
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
      existing = User.create!(email: "existing@example.com", password: "password", password_confirmation: "password")
      user = User.new(email: "new@example.com", webauthn_id: existing.webauthn_id)
      expect(user).not_to be_valid
      expect(user.errors[:webauthn_id]).to include("has already been taken")
    end
  end
end
