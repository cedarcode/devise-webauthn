# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_passkey_authentication(_mapping, controllers)
        resources :passkeys, only: %i[new create destroy], controller: controllers[:passkeys]

        resources :passkey_authentication_options, only: :index,
                                                   controller: controllers[:passkey_authentication_options]
        resources :passkey_registration_options, only: :index, controller: controllers[:passkey_registration_options]
      end

      def devise_two_factor_authentication(_mapping, controllers)
        resource :two_factor_authentication,
                 only: %i[new create],
                 controller: controllers[:two_factor_authentications]

        resources :second_factor_webauthn_credentials,
                  only: %i[new create update destroy],
                  controller: controllers[:second_factor_webauthn_credentials]

        resources :security_key_authentication_options, only: %i[index],
                                                        controller: controllers[:security_key_authentication_options]
        resources :security_key_registration_options, only: %i[index],
                                                      controller: controllers[:security_key_registration_options]
      end
    end
  end
end
