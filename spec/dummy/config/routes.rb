Rails.application.routes.draw do
  devise_for :users
  mount Devise::Webauthn::Engine => "/devise-webauthn"
end
