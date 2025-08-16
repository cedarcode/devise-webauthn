# frozen_string_literal: true

WebAuthn.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  config.allowed_origins = ["http://localhost:3030"]

  # Relying Party name for display purposes
  config.rp_name = "Devise WebAuthn Demo App"
end
