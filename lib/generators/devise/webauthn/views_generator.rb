# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views/devise", __dir__)

      desc "Copies Devise::Webauthn views to your application."

      argument :scope, required: false, default: nil,
                       desc: "The scope to copy views to"

      class_option :views, aliases: "-v", type: :array,
                           desc: "Select specific view directories to generate (sessions, passkeys)"

      def copy_views
        if options[:views]
          options[:views].each do |directory|
            view_directory directory.to_sym
          end
        else
          view_directory :passkeys
          view_directory :second_factor_webauthn_credentials
          view_directory :sessions
          view_directory :two_factor_authentications
        end
      end

      private

      def view_directory(name)
        directory name.to_s, "#{target_path}/#{name}"
      end

      def target_path
        "app/views/#{plural_scope || :devise}"
      end

      def plural_scope
        scope.presence && scope.underscore.pluralize
      end
    end
  end
end
