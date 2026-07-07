# frozen_string_literal: true

RSpec.describe Devise::Models::PasskeyAuthenticatable, type: :model do
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
    it "has many passkeys" do
      user = Account.create!(email: "user2@example.com", password: "password", password_confirmation: "password")
      passkey = WebauthnCredential.create!(account: user,
                                           external_id: "ext",
                                           public_key: "pk",
                                           name: "My Passkey",
                                           authentication_factor: :first_factor,
                                           sign_count: 0)
      expect(user.passkeys).to contain_exactly(passkey)
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
