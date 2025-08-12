# frozen_string_literal: true

RSpec.describe Passkey do
  it "allows building and saving a passkey" do
    user = User.new(email: "test@example.com", password: "password")
    passkey = described_class.new(name: "test", external_id: "external_id_123", public_key: "public_key_123",
                                  sign_count: 0, user:)

    expect(passkey.save).to be_truthy

    passkey.reload

    expect(passkey).to be_persisted
  end
end
