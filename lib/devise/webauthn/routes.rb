# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_passkey_authentication(_mapping, _controllers)
        resources :passkeys, only: %i[create], controller: "devise/webauthn/passkeys"
      end
    end
  end
end
