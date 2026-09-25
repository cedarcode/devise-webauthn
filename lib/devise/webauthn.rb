# frozen_string_literal: true

require "devise"
require "webauthn"

require_relative "webauthn/version"
require_relative "webauthn/challenge_stores/session"
require_relative "webauthn/challenge_stores/cache"
require_relative "webauthn/challenge_store_access"
require_relative "webauthn/public_key_credential_param"
require_relative "webauthn/two_factor_token"
require_relative "webauthn/pending_two_factor_sign_in"
require_relative "webauthn/credential_responses"
require_relative "webauthn/engine"
require_relative "webauthn/helpers/credentials_helper"
require_relative "webauthn/routes"
require_relative "webauthn/url_helpers"

module Devise
  module Webauthn
    mattr_accessor :challenge_store, default: ChallengeStores::Session

    module Test
      autoload :AuthenticatorHelpers, "devise/webauthn/test/authenticator_helpers"
    end
  end
end
