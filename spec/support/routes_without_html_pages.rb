# frozen_string_literal: true

# Routes the JSON actions of the passkey and security key controllers without their HTML pages, as an API does.
RSpec.shared_context "with routes for the JSON actions only" do
  around do |example|
    Rails.application.routes.draw do
      devise_scope :account do
        scope :accounts, as: :account do
          resources :passkeys, only: %i[create destroy], controller: "devise/passkeys"
          resources :second_factor_webauthn_credentials, only: %i[create update destroy],
                                                         controller: "devise/second_factor_webauthn_credentials"
        end
      end
    end
    example.run
  ensure
    Rails.application.reload_routes!
  end
end
