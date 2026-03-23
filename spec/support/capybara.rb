require "capybara/rspec"
require "capybara/playwright"

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end

Capybara.configure do |config|
  config.default_driver    = :rack_test   # fast default for non-JS specs
  config.javascript_driver = :playwright  # used when js: true metadata is set
end
