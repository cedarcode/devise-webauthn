# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"
require "devise/webauthn"
require "combustion"

Combustion.path = "spec/internal_api"
Combustion.initialize! :active_model, :active_record, :action_controller do
  config.load_defaults Rails.version.to_f
  config.api_only = true
  config.cache_store = :memory_store
  config.paths["app/models"] << File.expand_path("internal/app/models", __dir__)
end

require "rspec/rails"
require "api/support/api_request_helpers"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.use_transactional_fixtures = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include ActiveSupport::Testing::Assertions, type: :request
  config.include ApiRequestHelpers, type: :request
end
