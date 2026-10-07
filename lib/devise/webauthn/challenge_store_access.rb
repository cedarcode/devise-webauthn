# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStoreAccess
      private

      def challenge_store
        store = Devise::Webauthn.challenge_store
        store = Devise::Webauthn::ChallengeStores.const_get(store.to_s.camelize) if store.is_a?(Symbol)
        store.new(request)
      end

      # Some stores change the challenge, so the client must get the one `write` returns.
      def options_with_stored_challenge(purpose, options)
        options.as_json.merge(challenge: challenge_store.write(purpose, options.challenge))
      end
    end
  end
end
