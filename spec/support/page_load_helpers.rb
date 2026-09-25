# frozen_string_literal: true

module PageLoadHelpers
  class PageNotReloaded < StandardError; end

  # For forms that redirect back to the same URL, where `have_current_path` passes before the new page loads.
  def click_button_and_wait_for_page_load(locator)
    previous_time_origin = page.evaluate_script("performance.timeOrigin")
    click_button locator

    page.document.synchronize(errors: [PageNotReloaded, Selenium::WebDriver::Error::WebDriverError]) do
      raise PageNotReloaded if page.evaluate_script("performance.timeOrigin") == previous_time_origin
    end
  end
end
