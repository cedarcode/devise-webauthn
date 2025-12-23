# frozen_string_literal: true

RSpec.describe "Manage webauthn credentials", type: :system do
  let(:user) do
    Account.create!(
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

  describe "manages paskeys" do
    context "when user doesn't have passkeys" do
      it "allows creating a passkey" do
        visit new_account_passkey_path

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
        visit new_account_passkey_path

        fill_in "Passkey name", with: "My Passkey"
        click_button "Create Passkey"

        expect(page).to have_content("Passkey verification failed.")
      end
    end
  end

  describe "manages security keys" do
    context "when user doesn't have security keys" do
      it "allows creating a security key" do
        visit new_account_second_factor_webauthn_credential_path

        fill_in "Security Key name", with: "My Security Key"
        click_button "Create Security Key"

        expect(page).to have_content("Security Key created successfully.")
      end
    end

    context "when verification fails in the rp" do
      before do
        allow(WebAuthn.configuration.relying_party).to receive(:allowed_origins)
          .and_return(["http://localhost:5000"])
      end

      it "fails to create a security key" do
        visit new_account_second_factor_webauthn_credential_path

        fill_in "Security Key name", with: "My Security Key"
        click_button "Create Security Key"

        expect(page).to have_content("Webauthn credential verification failed.")
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    context "when user has existing security keys" do
      before do
        add_security_key_to_authenticator(authenticator, user, name: "Existing Key")
      end

      it "allows upgrading security key to passkey" do
        visit root_path

        within passkeys_section do
          expect(page).not_to have_content("Existing Key")
        end

        within security_keys_section do
          expect(page).to have_content("Existing Key")
          click_button "Upgrade to Passkey"
        end

        expect(page).to have_content("Security Key promoted to passkey successfully.")

        # Need to revisit the page because we're redirecting to the new security key page
        visit root_path

        within passkeys_section do
          expect(page).to have_content("Existing Key")
        end

        within security_keys_section do
          expect(page).not_to have_content("Existing Key")
          expect(page).not_to have_button("Upgrade to Passkey")
        end
      end
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

  private

  def security_keys_section
    find("div", text: "Security keys:")
  end

  def passkeys_section
    find("div", text: "Passkeys:")
  end
end
