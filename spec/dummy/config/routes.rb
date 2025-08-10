# frozen_string_literal: true

Rails.application.routes.draw do
  mount Devise::Webauthn::Engine => "/devise-webauthn"

  devise_for :users
end
