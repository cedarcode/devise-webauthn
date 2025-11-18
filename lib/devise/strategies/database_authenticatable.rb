# frozen_string_literal: true

require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    # Default strategy for signing in a user, based on their email and password in the database.
    class DatabaseAuthenticatable < Authenticatable
      def authenticate!
        resource  = password.present? && mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        if validate(resource){ hashed = true; resource.valid_password?(password) }
          if resource.second_factor_enabled?
            session[:current_authentication_resource_id] = resource.id
            redirect!(two_factor_authentication_path, {}, message: two_factor_required_message)
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
        Rails.application.routes.url_helpers.send(:"new_#{scope}_second_factor_authentication_path")
      end

      def two_factor_required_message
        I18n.t(:"#{scope}.two_factor_required", resource_name: scope, scope: "devise.failure", default: :two_factor_required)
      end
    end
  end
end

Warden::Strategies.add(:database_authenticatable, Devise::Strategies::DatabaseAuthenticatable)
