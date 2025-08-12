# frozen_string_literal: true

RSpec.describe User do
  it "allows building and saving a user" do
    user = described_class.new(email: "test@example.com", password: "password")

    expect(user.save).to be_truthy

    user.reload

    expect(user).to be_persisted
  end
end
