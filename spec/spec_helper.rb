# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require "devise/webauthn"
require "rails/generators/test_case"
require "support/generator_helper"

Bundler.require :default, :development

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

  config.before(:each, type: :system) do
    driven_by :selenium, using: ENV["HEADLESS"] == "false" ? :chrome : :headless_chrome
    Rails.application.reload_routes_unless_loaded

    Capybara.server_host = "localhost"
    WebAuthn.configuration.allowed_origins = ["http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"]
  end

  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Webauthn::Test::AuthenticatorHelpers, type: :system
end
