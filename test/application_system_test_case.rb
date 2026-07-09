require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CHROMEDRIVER_PATH"].present?
    Selenium::WebDriver::Chrome::Service.driver_path = ENV["CHROMEDRIVER_PATH"]
  end

  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
    options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
  end

  include Devise::Test::IntegrationHelpers # Rails >= 5
end
