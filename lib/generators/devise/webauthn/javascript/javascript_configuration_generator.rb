# frozen_string_literal: true

require "rails/generators"

module Devise
  module Webauthn
    class JavascriptConfigurationGenerator < Rails::Generators::Base
      hide!
      namespace "devise:webauthn:javascript"

      desc "Configure JavaScript loading for devise-webauthn"

      def configure_javascript
        if importmap?
          setup_importmap
        elsif using_node?
          setup_node
        else
          say "Could not detect JavaScript setup. Please manually configure webauthn.js loading.", :red
        end
      end

      private

      def importmap?
        File.exist?(File.join(destination_root, "config/importmap.rb"))
      end

      def using_node?
        File.exist?(File.join(destination_root, "package.json"))
      end

      def setup_importmap
        say "Detected importmap-rails setup", :green

        append_to_file "config/importmap.rb", %(pin "webauthn", to: "webauthn.js"\n)
        say "Added pin to config/importmap.rb", :green

        if File.exist?(File.join(destination_root, "app/javascript/application.js"))
          append_to_file "app/javascript/application.js", %(import "webauthn"\n)
          say "Added import to app/javascript/application.js", :green
        else
          say "Could not find app/javascript/application.js!", :red
          say "   Please add `import \"webauthn\"` to your application.js file manually."
        end
      end

      def setup_node
        say "Detected JavaScript bundler setup (Bun/Node)", :green

        if File.exist?(File.join(destination_root, "app/views/layouts/application.html.erb"))
          inject_into_file "app/views/layouts/application.html.erb",
                           %(\n    <%= javascript_include_tag "webauthn" %>),
                           before: "</head>"
          say "Added javascript_include_tag to app/views/layouts/application.html.erb", :green
        else
          say "Could not find app/views/layouts/application.html.erb.", :red
          say "   Please add `<%= javascript_include_tag \"webauthn\" %>`  within the <head> tag in your custom layout."
        end
      end
    end
  end
end
