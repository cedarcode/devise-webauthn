# frozen_string_literal: true

RSpec.describe "SignInWithPasskeys", type: :system do
  let!(:authenticator) { add_virtual_authenticator }

  after do
    authenticator.remove!
  end

  context "when authenticating a user" do
    let(:user) do
      User.create!(
        email: "testuser1@gmail.com",
        password: "password123"
      )
    end

    context "when user has passkeys" do
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
    end
  end

  context "when authenticating an admin" do
    let(:admin) do
      Admin.create!(
        email: "admin@test.com",
        password: "adminpassword"
      )
    end

    context "when admin has passkeys" do
      before do
        sign_in admin
        visit new_admin_passkey_path

        fill_in "Passkey name", with: "Admin Passkey"
        click_button "Create Passkey"

        page.has_text?("Passkey created successfully.")

        sign_out admin
      end

      it "allows to create a passkey and then sign in with it" do
        visit new_admin_session_path
        click_button "Log in with passkeys"

        expect(page).to have_content("Signed in successfully.")
      end
    end
  end
end
