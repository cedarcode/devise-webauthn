# frozen_string_literal: true

require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    # Default strategy for signing in a user, based on their email and password in the database.
    class DatabaseAuthenticatable < Authenticatable
      include Devise::Webauthn::PendingTwoFactorSignIn

      def authenticate!
        resource  = password.present? && mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        if validate(resource){ hashed = true; resource.valid_password?(password) }
          if second_factor_enabled?(resource)
            require_second_factor(resource)
          else
            remember_me(resource)
            resource.after_database_authentication
            success!(resource)
          end
        end

        # In paranoid mode, hash the password even when a resource doesn't exist for the given authentication key.
        # This is necessary to prevent enumeration attacks - e.g. the request is faster when a resource doesn't
        # exist in the database if the password hashing algorithm is not called.
        mapping.to.new.password = password if !hashed && Devise.paranoid
        unless resource
          Devise.paranoid ? fail(:invalid) : fail(:not_found_in_database)
        end
      end

      private

      def two_factor_authentication_path
        Rails.application.routes.url_helpers.send(:"new_#{scope}_two_factor_authentication_path")
      end

      def require_second_factor(resource)
        token = start_two_factor_sign_in_attempt_for(resource, scope: scope, remember_me: remember_me?)

        if navigational_request?
          redirect_to_two_factor_authentication
        else
          custom!(two_factor_required_response(token))
        end
      end

      def redirect_to_two_factor_authentication
        request.flash[:notice] = two_factor_required_message
        request.commit_flash
        redirect!(two_factor_authentication_path, {}, message: two_factor_required_message)
      end

      def navigational_request?
        Devise.navigational_formats.include?(request.format.try(:ref))
      end

      def two_factor_required_response(token)
        body = { error: two_factor_required_message }
        body[:two_factor_token] = token unless two_factor_token_stored_in_session?(scope)
        Rack::Response.new(body.to_json, 401, "content-type" => "application/json").finish
      end

      def two_factor_required_message
        I18n.t(:"#{scope}.two_factor_required", resource_name: scope, scope: "devise.failure", default: :two_factor_required)
      end

      def second_factor_enabled?(resource)
        resource.respond_to?(:second_factor_enabled?) && resource.second_factor_enabled?
      end
    end
  end
end

Warden::Strategies.add(:database_authenticatable, Devise::Strategies::DatabaseAuthenticatable)
