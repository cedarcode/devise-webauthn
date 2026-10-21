# frozen_string_literal: true

Devise.setup do |config|
  require "devise/orm/active_record"

  config.skip_session_storage = %i[http_auth params_auth]
  config.navigational_formats = []
  config.stretches = 1
  config.responder.error_status = :unprocessable_entity
end
