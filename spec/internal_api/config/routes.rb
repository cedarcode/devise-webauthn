# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :accounts, skip: %i[passkey_authentication two_factor_authentication]

  devise_scope :account do
    scope :accounts, as: :account do
      resources :passkeys, only: %i[create destroy], controller: "devise/passkeys"
      resources :passkey_authentication_options, only: :create, controller: "devise/passkey_authentication_options"
      resources :passkey_registration_options, only: :create, controller: "devise/passkey_registration_options"
      resource :two_factor_authentication, only: :create, controller: "devise/two_factor_authentications"
      resources :second_factor_webauthn_credentials, only: %i[create update destroy],
                                                     controller: "devise/second_factor_webauthn_credentials"
      resources :security_key_authentication_options, only: :create,
                                                      controller: "devise/security_key_authentication_options"
      resources :security_key_registration_options, only: :create,
                                                    controller: "devise/security_key_registration_options"
    end
  end
end
