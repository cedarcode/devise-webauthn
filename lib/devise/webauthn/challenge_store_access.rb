# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStoreAccess
      private

      def challenge_store
        Devise::Webauthn.challenge_store.new(request)
      end
    end
  end
end
