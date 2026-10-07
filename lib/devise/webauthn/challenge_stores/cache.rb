# frozen_string_literal: true

module Devise
  module Webauthn
    module ChallengeStores
      class Cache
        include CredentialChallenge

        cattr_accessor :cache
        cattr_accessor :expires_in, default: 5.minutes

        def initialize(request)
          @request = request
        end

        def write(purpose, challenge)
          store.write(key(purpose, challenge), true, expires_in: expires_in)
          challenge
        end

        def pending?(purpose)
          challenge.present? && store.exist?(key(purpose, challenge))
        end

        # `exist?` honours expiry, which MemoryStore#delete does not. `delete` decides which concurrent request wins.
        def consume(purpose)
          return if challenge.blank?
          return unless store.exist?(key(purpose, challenge))
          return unless store.delete(key(purpose, challenge))

          challenge
        end

        private

        def store
          cache || Rails.cache
        end

        def key(purpose, challenge)
          "devise_webauthn:challenge:#{purpose}:#{Digest::SHA256.hexdigest(challenge)}"
        end
      end
    end
  end
end
