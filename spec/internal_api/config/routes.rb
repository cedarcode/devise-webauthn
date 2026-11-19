# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :accounts, skip: %i[passkey_authentication two_factor_authentication]

  devise_scope :account do
    scope path: :accounts, module: :devise, as: :account do
      resources :passkeys, only: %i[create destroy]
      resources :second_factor_webauthn_credentials, only: %i[create update destroy]
      resource :two_factor_authentication, only: :create
      resources :passkey_authentication_options, :passkey_registration_options,
                :security_key_authentication_options, :security_key_registration_options, only: :create
    end
  end
end
