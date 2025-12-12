# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require "devise/webauthn"
require "rails/generators/test_case"
require "support/generator_helper"
require "combustion"

Combustion.initialize! :active_model, :active_record, :action_controller, :action_view do
  config.load_defaults Rails.version.to_f
end

require "rspec/rails"
require "capybara/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.use_transactional_fixtures = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Rails::Generators::Testing::Behavior, type: :generator
  config.include Rails::Generators::Testing::Assertions, type: :generator
  config.include FileUtils, type: :generator
  config.include GeneratorHelper, type: :generator
  config.include ActiveSupport::Testing::Assertions, type: :request
  config.include ActiveSupport::Testing::Assertions, type: :generator

  config.before(:each, type: :system) do
    driven_by :selenium, using: ENV["HEADLESS"] == "false" ? :chrome : :headless_chrome do |options|
      # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
      # options.add_argument('--disable-site-isolation-trials')
      # options.add_option('goog:loggingPrefs', browser: 'ALL')

      # For some reason, even though it's running in headless mode, chrome will treat a
      # 'foreground' tab as backgrounded if the surrounding window is occluded (aka
      # visually covered) by another window which causes it to halt animations,
      # resulting in tests errors.
      # This flag disables that behavior.
      options.add_argument "disable-backgrounding-occluded-windows"
    end

    # Selenium::WebDriver.logger.level = :debug

    Capybara.server_host = "localhost"
    WebAuthn.configuration.allowed_origins = ["http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"]

    # TODO: Remove when Devise fixes https://github.com/heartcombo/devise/issues/5705
    Rails.application.reload_routes_unless_loaded if Rails::VERSION::MAJOR >= 8
  end

  # config.after(:each, type: :system) do |example|
  #   if example.exception
  #     puts ""
  #     puts "========================================================== EXAMPLE #{example.full_description} FAILED =========================================================="
  #     puts "------------------------------ Browser console logs ------------------------------"
  #     puts page.driver.browser.logs.get(:browser)
  #     puts "=================================================================================================="
  #     puts ""
  #   else
  #     puts ""
  #     puts "========================================================== NO ERRORS DETECTED =========================================================="
  #     puts ""
  #   end
  # end

  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Webauthn::Test::AuthenticatorHelpers, type: :system
end
