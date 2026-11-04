# frozen_string_literal: true

WebAuthn.configure do |config|
  config.allowed_origins = ["http://localhost:9292"]
  config.rp_name = "Example Inc."
  config.rp_id = "localhost"
end

Devise::Webauthn.challenge_store = :cache
