# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStores
      class Signed
        include CredentialChallenge

        cattr_accessor :expires_in, default: 5.minutes

        def initialize(request)
          @request = request
        end

        # The client signs the returned challenge, so it comes back in clientDataJSON with no server state.
        def write(purpose, challenge)
          encoder.encode(verifier.generate(challenge, purpose: purpose, expires_in: expires_in))
        end

        def pending?(purpose)
          consume(purpose).present?
        end

        def consume(purpose)
          challenge if challenge && verifier.verified(encoder.decode(challenge), purpose: purpose)
        rescue ArgumentError, TypeError, EncodingError
          nil
        end

        private

        def verifier
          Rails.application.message_verifier(:devise_webauthn_challenge)
        end
      end
    end
  end
end
