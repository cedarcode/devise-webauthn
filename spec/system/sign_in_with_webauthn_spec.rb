# frozen_string_literal: true

RSpec.describe "SignInWithWebauthn", type: :system do
  let(:user) do
    Account.create!(
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
      add_passkey_to_authenticator(authenticator, user)
    end

    it "allows to create a passkey and then sign in with it" do
      visit new_account_session_path
      click_button "Log in with passkeys"

      expect(page).to have_content("Signed in successfully.")
    end

    it "can use them as second factor authentication" do
      visit new_account_session_path

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
      add_security_key_to_authenticator(authenticator, user)
    end

    it "can use them as second factor authentication" do
      visit new_account_session_path

      fill_in "Email", with: user.email
      fill_in "Password", with: "$3cretp@ssword123"

      click_button "Log in"

      expect(page).to have_content("Two-factor authentication is required to sign in.")

      click_button "Use security key"

      expect(page).to have_content("Signed in successfully.")
      expect(remember_cookie).to be_nil
    end

    context "when something fails" do
      before do
        allow(WebAuthn.configuration.relying_party).to receive(:allowed_origins)
          .and_return(["http://localhost:5000"])
      end

      it "redirects to new two factor authentication page" do
        visit new_account_session_path

        fill_in "Email", with: user.email
        fill_in "Password", with: "$3cretp@ssword123"

        click_button "Log in"

        expect(page).to have_content("Two-factor authentication is required to sign in.")

        click_button "Use security key"

        expect(page).to have_content("Webauthn credential verification failed.")
        expect(page).to have_button("Use security key")
      end
    end

    context "when checking the remember_me checkbox" do
      it "sets remember cookie when remember me is checked" do
        visit new_account_session_path

        fill_in "Email", with: user.email
        fill_in "Password", with: "$3cretp@ssword123"
        check "Remember me"

        click_button "Log in"

        expect(page).to have_content("Two-factor authentication is required to sign in.")

        click_button "Use security key"

        expect(page).to have_content("Signed in successfully.")
        expect(remember_cookie).to be_present
      end
    end
  end

  def remember_cookie
    page.driver.browser.manage.cookie_named("remember_account_token")
  rescue Selenium::WebDriver::Error::NoSuchCookieError
    nil
  end
end
