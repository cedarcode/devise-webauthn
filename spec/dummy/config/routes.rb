Rails.application.routes.draw do
  mount Devise::Webauthn::Engine => "/devise-webauthn"
end
