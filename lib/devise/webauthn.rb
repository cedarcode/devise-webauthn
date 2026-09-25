# frozen_string_literal: true

require "devise"
require "webauthn"

require_relative "webauthn/version"
require_relative "webauthn/challenge_stores/session"
require_relative "webauthn/engine"
require_relative "webauthn/helpers/credentials_helper"
require_relative "webauthn/routes"
require_relative "webauthn/url_helpers"

module Devise
  module Webauthn
    mattr_accessor :challenge_store, default: ChallengeStores::Session

    def self.challenge_store_for(request)
      challenge_store.new(request)
    end

    module Test
      autoload :AuthenticatorHelpers, "devise/webauthn/test/authenticator_helpers"
    end
  end
end
