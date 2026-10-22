# frozen_string_literal: true

# Signs in with a passkey outside Devise::SessionsController, as an app's own passkey endpoint can.
class PasskeySessionsController < ApplicationController
  def create
    allow_params_authentication!
    warden.authenticate!(:passkey_authenticatable, scope: :account)
    head :created
  end
end
