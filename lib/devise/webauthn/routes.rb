# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_passkey_authentication(_mapping, controllers)
        resources :passkeys, only: %i[new create destroy], controller: controllers[:passkeys]

        resource :passkey do
          resources :authentication_options, only: :index, controller: controllers[:"passkey/authentication_options"]
          resources :registration_options, only: :index, controller: controllers[:"passkey/registration_options"]
        end
      end

      def devise_two_factor_authentication(_mapping, controllers)
        resource :two_factor_authentication,
                 only: %i[new create],
                 controller: controllers[:two_factor_authentications]

        resources :second_factor_webauthn_credentials,
                  only: %i[new create update destroy],
                  controller: controllers[:second_factor_webauthn_credentials]

        resource :security_key do
          resources :authentication_options, only: %i[index],
                                             controller: controllers[:"security_key/authentication_options"]
          resources :registration_options, only: %i[index],
                                           controller: controllers[:"security_key/registration_options"]
        end
      end
    end
  end
end
