Rails.application.routes.draw do
  devise_for :users
  mount Devise::Webauthn::Engine, at: "/devise-webauthn"
end
