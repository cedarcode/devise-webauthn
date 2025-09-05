# frozen_string_literal: true

RSpec.describe "CreatePasskeys", type: :system do
  let(:user) do
    User.create!(
      email: "testuser1@gmail.com",
      password: "password123"
    )
  end

  let!(:authenticator) { add_virtual_authenticator }

  before do
    sign_in user
  end

  after do
    authenticator.remove!
  end

  context "when user doesn't have passkeys" do
    it "allows creating a passkey" do
      visit new_user_passkey_path

      fill_in "Passkey name", with: "My Passkey"
      click_button "Create Passkey"

      expect(page).to have_content("Passkey created successfully.")
    end
  end

  context "when verification fails in the rp" do
    before do
      allow(WebAuthn.configuration.relying_party).to receive(:allowed_origins)
        .and_return(["http://localhost:5000"])
    end

    it "fails to create a passkey" do
      visit new_user_passkey_path

      fill_in "Passkey name", with: "My Passkey"
      click_button "Create Passkey"

      expect(page).to have_content("Passkey verification failed.")
    end
  end
end
