# frozen_string_literal: true

RSpec.describe "CreatePasskeys", type: :system do
  let(:user) do
    User.create!(
      email: "testuser1@gmail.com",
      password: "password123"
    )
  end

  before do
    @authenticator = add_virtual_authenticator
  end

  after do
    @authenticator.remove! # rubocop:disable RSpec/InstanceVariable
  end

  context "when user doesn't have passkeys" do
    it "allows creating a passkey" do
      sign_in user
      visit edit_user_registration_path(user)

      fill_in "Passkey name", with: "My Passkey"
      click_button "Create Passkey"

      expect(page).to have_content("My Passkey")
    end
  end
end
