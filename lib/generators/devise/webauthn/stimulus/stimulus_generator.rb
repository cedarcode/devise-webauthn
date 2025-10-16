# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class StimulusGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("templates", __dir__)

      desc "Copy DeviseWebauthn Stimulus controller to your application"

      def copy_stimulus_controller
        copy_file "webauthn_credentials_controller.js",
                  "app/javascript/controllers/webauthn_credentials_controller.js"
      end

      def show_instructions
        say "✓ Stimulus controller setup complete!", :green
        say "The webauthn_credentials controller has been installed and will be automatically registered by Stimulus."
      end
    end
  end
end
