# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_passkey_authentication(_mapping, controllers)
        resources :passkeys, only: %i[new create destroy], controller: controllers[:passkeys]
      end

      def devise_second_factor_authentication(_mapping, controllers)
        resources :second_factor_keys,
                  only: %i[new create destroy],
                  controller: controllers[:second_factor_keys]
      end
    end
  end
end
