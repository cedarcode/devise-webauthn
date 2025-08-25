# frozen_string_literal: true

module PasskeyHelper
  def add_virtual_authenticator
    options = Selenium::WebDriver::VirtualAuthenticatorOptions.new
    options.user_verification = true
    options.user_verified = true
    page.driver.browser.add_virtual_authenticator(options)
  end
end
