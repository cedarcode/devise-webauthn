# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_passkey_authentication(_mapping, controllers)
        resources :passkeys, only: %i[new create destroy], controller: controllers[:passkeys] do
          get :options_for_get, on: :collection
          get :options_for_create, on: :collection
        end
      end

      def devise_two_factor_authentication(_mapping, controllers)
        resource :two_factor_authentication,
                 only: %i[new create],
                 controller: controllers[:two_factor_authentications]

        resources :second_factor_webauthn_credentials,
          only: %i[new create destroy],
          controller: controllers[:second_factor_webauthn_credentials] do
            get :options_for_get, on: :collection
            get :options_for_create, on: :collection
          end
      end
    end
  end
end
