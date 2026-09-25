# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStores
      class Session
        KEYS = {
          passkey_authentication: :authentication_challenge,
          two_factor_authentication: :two_factor_authentication_challenge,
          registration: :webauthn_challenge
        }.freeze

        def initialize(request)
          @session = request.session
        end

        def write(purpose, challenge)
          @session[KEYS.fetch(purpose)] = challenge
        end

        def pending?(purpose, _credential)
          @session[KEYS.fetch(purpose)].present?
        end

        def consume(purpose, _credential)
          @session.delete(KEYS.fetch(purpose))
        end
      end
    end
  end
end
