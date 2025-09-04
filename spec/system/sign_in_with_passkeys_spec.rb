# frozen_string_literal: true

RSpec.describe "SignInWithPasskeys", type: :system do
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

  it "allows to create a passkey and then sign in with it" do
    visit new_user_passkey_path

    fill_in "Passkey name", with: "My Passkey"
    click_button "Create Passkey"

    expect(page).to have_content("Passkey created successfully.")

    sign_out user

    visit new_user_session_path
    click_button "Log in with passkeys"

    expect(page).to have_content("Signed in successfully.")
  end
end
