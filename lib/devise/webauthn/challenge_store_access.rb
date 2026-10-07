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
    end
  end
end
