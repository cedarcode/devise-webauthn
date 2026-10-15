# frozen_string_literal: true

module Devise
  module Webauthn
    module StateStoreAccess
      private

      def state_store
        store = Devise::Webauthn.state_store
        store = Devise::Webauthn::StateStores.const_get(store.to_s.camelize) if store.is_a?(Symbol)
        store.new(request)
      end
    end
  end
end
