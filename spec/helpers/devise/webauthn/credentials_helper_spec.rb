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
    require "devise/version"
    Rails.application.reload_routes_unless_loaded if Rails::VERSION::MAJOR >= 8 && Devise::VERSION < "5"
  end

  def parse(html)
    Capybara.string(html)
  end

  def have_hidden_credential_field
    have_css(
      "input[type='hidden'][name='public_key_credential'][data-webauthn-target='response']",
      visible: :hidden
    )
  end

  describe "#passkey_creation_form_for" do
    it "renders a form with webauthn_create element and hidden credential field" do
      html = helper.passkey_creation_form_for(user) do |form|
        form.submit "Create Passkey"
      end

      page = parse(html)
      expect(page).to have_css("form")
      expect(page).to have_css("webauthn-create[data-options-url='/accounts/passkey_registration_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Create Passkey")
    end

    it "accepts options passed directly" do
      html = helper.passkey_creation_form_for(
        user,
        class: "custom-form",
        id: "passkey-form",
        data: { turbo: false }
      ) do |form|
        form.submit "Create"
      end

      expect(parse(html)).to have_css('form.custom-form#passkey-form[data-turbo="false"]')
    end

    it "allows custom content in the block" do
      html = helper.passkey_creation_form_for(user) do |form|
        helper.content_tag(:div, class: "button-wrapper") do
          form.submit "Create", class: "btn-primary"
        end
      end

      page = parse(html)
      expect(page).to have_css("div.button-wrapper")
      expect(page).to have_css("input.btn-primary[type='submit']")
    end
  end

  describe "#login_with_passkey_form_for" do
    it "renders a form with webauthn_get element and hidden credential field" do
      html = helper.login_with_passkey_form_for(:account) do |form|
        form.submit "Log in with passkeys"
      end

      page = parse(html)
      expect(page).to have_css("form[action='/accounts/sign_in']")
      expect(page).to have_css("webauthn-get[data-options-url='/accounts/passkey_authentication_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Log in with passkeys")
    end

    it "accepts options passed directly" do
      html = helper.login_with_passkey_form_for(
        :account,
        class: "passkey-form",
        id: "passkey-login",
        data: { controller: "auth" }
      ) do |form|
        form.submit "Login"
      end

      expect(parse(html)).to have_css('form.passkey-form#passkey-login[data-controller="auth"]')
    end

    it "allows custom content in the block" do
      html = helper.login_with_passkey_form_for(:account) do |form|
        # artifact of the test, concat simulates ERB's <%= %>
        helper.concat form.submit("Sign in", class: "btn-primary")
        helper.concat form.check_box(:remember_me)
        helper.concat form.label(:remember_me, "Remember me")
      end

      page = parse(html)

      expect(page).to have_css("input.btn-primary[type='submit']")
      expect(page).to have_css("input[type='checkbox'][name='remember_me']")
      expect(page).to have_css("label[for='remember_me']", text: "Remember me")
    end
  end

  describe "#security_key_creation_form_for" do
    it "renders a form with webauthn_create element" do
      html = helper.security_key_creation_form_for(user) do |form|
        form.submit "Add Security Key"
      end

      page = parse(html)
      expect(page).to have_css("form")
      expect(page).to have_css("webauthn-create[data-options-url='/accounts/security_key_registration_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Add Security Key")
    end

    it "accepts options passed directly" do
      html = helper.security_key_creation_form_for(
        user,
        class: "security-key-form",
        id: "security-key-registration",
        data: { turbo: false }
      ) do |form|
        form.submit "Add"
      end

      expect(parse(html)).to have_css('form.security-key-form#security-key-registration[data-turbo="false"]')
    end

    it "allows custom content in the block" do
      html = helper.security_key_creation_form_for(user) do |form|
        helper.content_tag(:div, class: "button-wrapper") do
          form.submit "Add", class: "btn-primary"
        end
      end

      page = parse(html)
      expect(page).to have_css("div.button-wrapper")
      expect(page).to have_css("input.btn-primary[type='submit']")
    end
  end

  describe "#login_with_security_key_form_for" do
    it "renders a form with webauthn_get element" do
      html = helper.login_with_security_key_form_for(:account) do |form|
        form.submit "Use security key"
      end

      page = parse(html)
      expect(page).to have_css("form")
      expect(page).to have_css("webauthn-get[data-options-url='/accounts/security_key_authentication_options']")
      expect(page).to have_hidden_credential_field
      expect(page).to have_button("Use security key")
    end

    it "accepts options passed directly" do
      html = helper.login_with_security_key_form_for(
        :account,
        class: "two-factor-form",
        id: "security-key-auth",
        data: { turbo_method: "post" }
      ) do |form|
        form.submit "Verify"
      end

      expect(parse(html)).to have_css('form.two-factor-form#security-key-auth[data-turbo-method="post"]')
    end

    it "allows custom content in the block" do
      html = helper.login_with_security_key_form_for(:account) do |form|
        helper.safe_join([helper.content_tag(:p, "Authenticate with your security key"), form.submit("Authenticate")])
      end

      page = parse(html)
      expect(page).to have_css("p", text: "Authenticate with your security key")
      expect(page).to have_button("Authenticate")
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
