# frozen_string_literal: true

module Devise
  module Webauthn
    module StateStores
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

        def pending?(purpose)
          @session[KEYS.fetch(purpose)].present?
        end

        def consume(purpose)
          @session.delete(KEYS.fetch(purpose))
        end

        # Tokens are not recorded: browser sign-ins clear theirs from the session,
        # and API tokens work until they expire.
        def issue_two_factor_token(_jti); end

        def two_factor_token_issued?(_jti)
          true
        end

        def consume_two_factor_token(jti)
          jti
        end
      end
    end
  end
end
