# frozen_string_literal: true

RSpec.describe Devise::Webauthn::CredentialsHelper, type: :helper do
  let(:account) do
    Account.create!(email: "test@example.com", password: "password123", webauthn_id: "test-webauthn-id")
  end

  before do
    allow(helper).to receive(:session).and_return({})
  end

  def parsed(html)
    Capybara.string(html)
  end

  describe "#passkey_creation_form_for" do
    before do
      allow(helper).to receive(:passkeys_path).with(account).and_return("/passkeys")
      allow(helper).to receive(:passkey_registration_options_path).with(account).and_return("/passkey_options")
    end

    it "renders form with default attributes" do
      html = helper.passkey_creation_form_for(account) { |_f| "" }

      expect(parsed(html)).to have_css('form[action="/passkeys"][method="post"]')
    end

    it "renders form with custom form_attributes" do
      html = helper.passkey_creation_form_for(
        account,
        form_attributes: {
          class: "my-form",
          id: "passkey-form",
          data: { turbo: false }
        }
      ) { |_f| "" }

      expect(parsed(html)).to have_css('form.my-form#passkey-form[data-turbo="false"]')
    end
  end

  describe "#login_with_passkey_button" do
    before do
      allow(helper).to receive_messages(
        passkey_authentication_options_path: "/passkey_auth_options",
        resource: account
      )
    end

    it "renders form with default attributes" do
      html = helper.login_with_passkey_button("Login", session_path: "/sessions")

      expect(parsed(html)).to have_css('form[action="/sessions"][method="post"]')
      expect(parsed(html)).to have_css('button[type="submit"]', text: "Login")
    end

    it "renders form with custom form_attributes" do
      html = helper.login_with_passkey_button(
        "Login",
        session_path: "/sessions",
        form_attributes: {
          class: "auth-form",
          id: "passkey-login",
          data: { controller: "auth" }
        }
      )

      expect(parsed(html)).to have_css('form.auth-form#passkey-login[data-controller="auth"]')
    end

    it "renders button with custom button_attributes" do
      html = helper.login_with_passkey_button(
        "Login",
        session_path: "/sessions",
        button_attributes: {
          class: "btn btn-primary",
          id: "passkey-btn",
          data: { disable_with: "Authenticating..." }
        }
      )

      expect(parsed(html)).to have_css('button.btn.btn-primary#passkey-btn[data-disable-with="Authenticating..."]')
    end

    it "renders with both form_attributes and button_attributes" do
      html = helper.login_with_passkey_button(
        "Login",
        session_path: "/sessions",
        form_attributes: { class: "passkey-form", data: { turbo: false } },
        button_attributes: { class: "submit-btn", disabled: true }
      )

      expect(parsed(html)).to have_css('form.passkey-form[data-turbo="false"]')
      expect(parsed(html)).to have_css("button.submit-btn[disabled]")
    end
  end

  describe "#security_key_creation_form_for" do
    before do
      allow(helper).to receive(:second_factor_webauthn_credentials_path)
        .with(account).and_return("/security_keys")
      allow(helper).to receive(:security_key_registration_options_path)
        .with(account).and_return("/security_key_options")
    end

    it "renders form with default attributes" do
      html = helper.security_key_creation_form_for(account) { |_f| "" }

      expect(parsed(html)).to have_css('form[action="/security_keys"][method="post"]')
    end

    it "renders form with custom form_attributes" do
      html = helper.security_key_creation_form_for(
        account,
        form_attributes: {
          class: "webauthn-form",
          id: "security-key-registration",
          data: { turbo: false }
        }
      ) { |_f| "" }

      expect(parsed(html)).to have_css('form.webauthn-form#security-key-registration[data-turbo="false"]')
    end
  end

  describe "#login_with_security_key_button" do
    before do
      allow(helper).to receive(:two_factor_authentication_path)
        .with(account).and_return("/two_factor")
      allow(helper).to receive(:security_key_authentication_options_path)
        .with(account).and_return("/security_key_auth_options")
    end

    it "renders form with default attributes" do
      html = helper.login_with_security_key_button("Authenticate", resource: account)

      expect(parsed(html)).to have_css('form[action="/two_factor"][method="post"]')
      expect(parsed(html)).to have_css('button[type="submit"]', text: "Authenticate")
    end

    it "renders form with custom form_attributes" do
      html = helper.login_with_security_key_button(
        "Authenticate",
        resource: account,
        form_attributes: {
          class: "mfa-form",
          id: "security-key-auth",
          data: { turbo_method: "post" }
        }
      )

      expect(parsed(html)).to have_css('form.mfa-form#security-key-auth[data-turbo-method="post"]')
    end

    it "renders button with custom button_attributes" do
      html = helper.login_with_security_key_button(
        "Authenticate",
        resource: account,
        button_attributes: {
          class: "btn btn-secondary",
          id: "security-key-btn",
          data: { action: "click->webauthn#authenticate" }
        }
      )

      expect(parsed(html)).to have_css(
        'button.btn.btn-secondary#security-key-btn[data-action="click->webauthn#authenticate"]'
      )
    end

    it "renders with both form_attributes and button_attributes" do
      html = helper.login_with_security_key_button(
        "Authenticate",
        resource: account,
        form_attributes: { class: "two-factor-form", data: { controller: "mfa" } },
        button_attributes: { class: "auth-btn", data: { testid: "security-key-submit" } }
      )

      expect(parsed(html)).to have_css('form.two-factor-form[data-controller="mfa"]')
      expect(parsed(html)).to have_css('button.auth-btn[data-testid="security-key-submit"]')
    end
  end
end
