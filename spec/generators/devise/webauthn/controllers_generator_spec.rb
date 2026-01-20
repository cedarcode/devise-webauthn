# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/controllers_generator"

RSpec.describe Devise::Webauthn::ControllersGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
  end

  context "when no scope is passed" do
    let(:generator_instance) { generator }

    it "does not create anything" do
      expect { invoke generator_instance }.to raise_error(Thor::RequiredArgumentMissingError,
                                                          "No value provided for required arguments 'scope'")
      assert_no_file "app/controllers/passkeys_controller.rb"
      assert_no_file "app/controllers/second_factor_webauthn_credentials_controller.rb"
      assert_no_file "app/controllers/two_factor_authentications_controller.rb"
      assert_no_file "app/controllers/passkey/authenticator_options_controller.rb"
      assert_no_file "app/controllers/passkey/registration_options_controller.rb"
      assert_no_file "app/controllers/security_key/authenticator_options_controller.rb"
      assert_no_file "app/controllers/security_key/registration_options_controller.rb"
    end
  end

  context "when using a custom scope" do
    let(:generator_instance) { generator(["users"]) }

    it "create controllers properly scoped with scope param" do
      invoke generator_instance

      assert_file "app/controllers/users/passkeys_controller.rb", /Users::PasskeysController/
      assert_file "app/controllers/users/second_factor_webauthn_credentials_controller.rb", /Users::SecondFactorWebauthnCredentialsController/
      assert_file "app/controllers/users/two_factor_authentications_controller.rb", /Users::TwoFactorAuthenticationsController/
      assert_file "app/controllers/users/passkey/authentication_options_controller.rb", /Users::Passkey::AuthenticationOptionsController/
      assert_file "app/controllers/users/passkey/registration_options_controller.rb", /Users::Passkey::RegistrationOptionsController/
      assert_file "app/controllers/users/security_key/authentication_options_controller.rb", /Users::SecurityKey::AuthenticationOptionsController/
      assert_file "app/controllers/users/security_key/registration_options_controller.rb", /Users::SecurityKey::RegistrationOptionsController/
    end
  end
end
