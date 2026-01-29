# frozen_string_literal: true

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe Devise::Webauthn::CredentialsHelper, type: :helper do
  let(:user) do
    Account.create!(
      email: "testuser@example.com",
      password: "$3cretp@ssword123"
    )
  end

  before do
    allow(helper).to receive_messages(resource: user, session: {})
  end

  def parsed(html)
    Capybara.string(html)
  end

  def have_hidden_credential_field
    have_css(
      "input[type='hidden'][name='public_key_credential'][data-webauthn-target='response']",
      visible: :hidden
    )
  end

  describe "#passkey_creation_form_for" do
    it "renders a form with webauthn_create element" do
      html = helper.passkey_creation_form_for(user) do |form|
        form.submit "Create Passkey"
      end

      page = parsed(html)
      expect(page).to have_css("form")
      expect(page).to have_css("webauthn-create[data-options-url='/accounts/passkey_registration_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Create Passkey")
    end

    it "accepts form_classes option" do
      html = helper.passkey_creation_form_for(user, form_classes: "custom-form") do |form|
        form.submit "Create"
      end

      expect(parsed(html)).to have_css("form.custom-form")
    end
  end

  describe "#login_with_passkey_form_for" do
    it "renders a form with webauthn_get element" do
      html = helper.login_with_passkey_form_for(session_path: "/accounts/sign_in") do |form|
        form.submit "Log in with passkeys"
      end

      page = parsed(html)
      expect(page).to have_css("form[action='/accounts/sign_in']")
      expect(page).to have_css("webauthn-get[data-options-url='/accounts/passkey_authentication_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Log in with passkeys")
    end

    it "accepts form_classes option" do
      html = helper.login_with_passkey_form_for(session_path: "/sign_in", form_classes: "passkey-form") do |form|
        form.submit "Login"
      end

      expect(parsed(html)).to have_css("form.passkey-form")
    end

    it "allows custom content in the block" do
      html = helper.login_with_passkey_form_for(session_path: "/sign_in") do |form|
        helper.content_tag(:div, class: "button-wrapper") do
          form.submit "Sign in", class: "btn-primary"
        end
      end

      page = parsed(html)
      expect(page).to have_css("div.button-wrapper")
      expect(page).to have_css("input.btn-primary[type='submit']")
    end
  end

  describe "#security_key_creation_form_for" do
    it "renders a form with webauthn_create element" do
      html = helper.security_key_creation_form_for(user) do |form|
        form.submit "Add Security Key"
      end

      page = parsed(html)
      expect(page).to have_css("form")
      expect(page).to have_css("webauthn-create[data-options-url='/accounts/security_key_registration_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Add Security Key")
    end

    it "accepts form_classes option" do
      html = helper.security_key_creation_form_for(user, form_classes: "security-key-form") do |form|
        form.submit "Add"
      end

      expect(parsed(html)).to have_css("form.security-key-form")
    end
  end

  describe "#login_with_security_key_form_for" do
    it "renders a form with webauthn_get element" do
      html = helper.login_with_security_key_form_for(resource: user) do |form|
        form.submit "Use security key"
      end

      page = parsed(html)
      expect(page).to have_css("form")
      expect(page).to have_css("webauthn-get[data-options-url='/accounts/security_key_authentication_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Use security key")
    end

    it "accepts form_classes option" do
      html = helper.login_with_security_key_form_for(resource: user, form_classes: "two-factor-form") do |form|
        form.submit "Verify"
      end

      expect(parsed(html)).to have_css("form.two-factor-form")
    end

    it "allows custom content in the block" do
      html = helper.login_with_security_key_form_for(resource: user) do |form|
        helper.safe_join([helper.content_tag(:p, "Authenticate with your security key"), form.submit("Authenticate")])
      end

      page = parsed(html)
      expect(page).to have_css("p", text: "Authenticate with your security key")
      expect(page).to have_button("Authenticate")
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
