# frozen_string_literal: true

require "capybara/selenium/driver"

# Chrome 158 rejects the "*" origin that Capybara 3.40 clears on reset.
# https://github.com/teamcapybara/capybara/issues/2865
module ChromeResetWithoutWildcardOrigin
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super(cmd, params.merge(origin: Capybara.current_session.server.base_url))
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWithoutWildcardOrigin)
