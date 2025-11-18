# frozen_string_literal: true

RSpec.describe "SignInWithWebauthn", type: :system do
  let(:user) do
    User.create!(
      email: "testuser1@gmail.com",
      password: "$3cretp@ssword123"
    )
  end

  let!(:authenticator) { add_virtual_authenticator }

  after do
    authenticator.remove!
  end

  describe "sign in using passkeys" do
    before do
      sign_in user
      visit new_user_passkey_path

      fill_in "Passkey name", with: "My Passkey"
      click_button "Create Passkey"

      page.has_text?("Passkey created successfully.")

      sign_out user
    end

    it "allows to create a passkey and then sign in with it" do
      visit new_user_session_path
      click_button "Log in with passkeys"

      expect(page).to have_content("Signed in successfully.")
    end

    it "can use them as second factor authentication" do
      visit new_user_session_path

      fill_in "Email", with: user.email
      fill_in "Password", with: "$3cretp@ssword123"

      click_button "Log in"

      expect(page).to have_content("Two-factor authentication is required to sign in.")

      click_button "Use security key"

      expect(page).to have_content("Signed in successfully.")
    end
  end

  describe "sign in with security keys as second factor" do
    before do
      sign_in user
      visit new_user_second_factor_key_path

      fill_in "Security Key name", with: "My Security Key"
      click_button "Create Security Key"

      page.has_text?("Security Key created successfully.")

      sign_out user
    end

    it "can use them as second factor authentication" do
      visit new_user_session_path

      fill_in "Email", with: user.email
      fill_in "Password", with: "$3cretp@ssword123"

      click_button "Log in"

      expect(page).to have_content("Two-factor authentication is required to sign in.")

      click_button "Use security key"

      expect(page).to have_content("Signed in successfully.")
    end
  end
end
