# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    module FilesConfigurator
      extend ActiveSupport::Concern

      private

      def setup_configuration_files
        create_initializer
      end

      def create_initializer
        template "webauthn.rb", "config/initializers/webauthn.rb"
        say "Created initializer: config/initializers/webauthn.rb", :green
      end
    end
  end
end
