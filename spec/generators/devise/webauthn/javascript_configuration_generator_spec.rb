# frozen_string_literal: true

require "spec_helper"
require "generators/devise/webauthn/javascript/javascript_configuration_generator"

RSpec.describe Devise::Webauthn::JavascriptConfigurationGenerator, type: :generator do
  tests described_class
  destination File.expand_path("../../../tmp", __dir__)

  before do
    prepare_destination
  end

  context "when using importmap-rails" do
    before do
      create_importmap_file
    end

    context "with application.js present" do
      before do
        create_application_js_file
        invoke generator
      end

      it "appends the pin to config/importmap.rb" do
        assert_file "config/importmap.rb", %r{pin "devise/webauthn", to: "devise/webauthn.js"}
      end

      it "appends the import to app/javascript/application.js" do
        assert_file "app/javascript/application.js", %r{import "devise/webauthn"}
      end
    end

    context "without application.js" do
      before do
        invoke generator
      end

      it "appends the pin to config/importmap.rb" do
        assert_file "config/importmap.rb", %r{pin "devise/webauthn", to: "devise/webauthn.js"}
      end

      it "does not create application.js" do
        assert_no_file "app/javascript/application.js"
      end
    end
  end

  context "when using Node" do
    before do
      create_package_json_file
    end

    context "with application layout present" do
      before do
        create_application_layout_file
        invoke generator
      end

      it "injects javascript_include_tag into the layout" do
        assert_file "app/views/layouts/application.html.erb",
                    %r{<%= javascript_include_tag "devise/webauthn" %>}
      end

      it "places the tag before </head>" do
        content = File.read(File.join(destination_root, "app/views/layouts/application.html.erb"))
        expect(content).to match(%r{<%= javascript_include_tag "devise/webauthn" %>\s*</head>})
      end
    end

    context "without application layout" do
      before do
        invoke generator
      end

      it "does not create application layout" do
        assert_no_file "app/views/layouts/application.html.erb"
      end
    end
  end

  context "when no JavaScript setup is detected" do
    before do
      invoke generator
    end

    it "does not create any files" do
      assert_no_file "config/importmap.rb"
      assert_no_file "app/javascript/application.js"
      assert_no_file "app/views/layouts/application.html.erb"
    end
  end

  def create_importmap_file
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/importmap.rb"), "# Pin npm packages\n")
  end

  def create_application_js_file
    FileUtils.mkdir_p(File.join(destination_root, "app/javascript"))
    File.write(File.join(destination_root, "app/javascript/application.js"), "// Application JS\n")
  end

  def create_package_json_file
    File.write(File.join(destination_root, "package.json"), '{"name": "test-app"}')
  end

  def create_application_layout_file
    FileUtils.mkdir_p(File.join(destination_root, "app/views/layouts"))
    File.write(
      File.join(destination_root, "app/views/layouts/application.html.erb"),
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Test App</title>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      HTML
    )
  end
end
