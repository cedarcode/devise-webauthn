# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views/devise", __dir__)

      desc "Copies Devise::Webauthn views to your application."

      argument :scope, required: false, default: nil,
                       desc: "The scope to copy views to"

      def copy_views
        view_directory :passkeys
        view_directory :sessions
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
