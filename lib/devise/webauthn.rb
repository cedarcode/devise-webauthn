# frozen_string_literal: true

require "devise"
require "webauthn"

require_relative "webauthn/version"
require_relative "webauthn/engine"
require_relative "models/passkey_authenticatable"
require_relative "strategies/passkey_authenticatable"
require_relative "webauthn/helpers/passkeys_helper"
require_relative "webauthn/routes"

module Devise
  module Webauthn
  end
end
