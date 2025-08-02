# frozen_string_literal: true

Devise::Webauthn::Engine.routes.draw do
  resources :passkeys, only: %i[create]
end
