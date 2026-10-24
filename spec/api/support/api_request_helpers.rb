# frozen_string_literal: true

module ApiRequestHelpers
  # API clients send their credentials with every request, so this signs in for the next request only.
  def authenticate_next_request_as(account)
    sign_in account, scope: :account
  end

  def random_challenge
    WebAuthn.configuration.encoder.encode(SecureRandom.random_bytes(32))
  end
end
