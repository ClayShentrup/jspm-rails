# frozen_string_literal: true

require 'playwright'
require 'playwright/test'

# System specs talk to the browser through Playwright's own API. Capybara only
# runs the app server, through a driver that does nothing else.
# https://playwright-ruby-client.vercel.app/docs/article/guides/rails_integration_with_null_driver
# A Capybara driver that only asks for the app server.
class NullDriver < Capybara::Driver::Base
  def needs_server?
    true
  end
end

Capybara.register_driver(:null) { NullDriver.new }

# Gives each system example a Playwright page in place of Capybara's.
module PlaywrightPage
  attr_reader :page
end

RSpec.configure do |config|
  config.include(PlaywrightPage, type: :system)
  config.include(Playwright::Test::Matchers, type: :system)

  config.around(:each, type: :system) do |example|
    driven_by(:null)
    cli = File.expand_path('../../node_modules/.bin/playwright', __dir__)
    Playwright.create(playwright_cli_executable_path: cli) do |playwright|
      playwright.chromium.launch(headless: ENV.fetch('HEADLESS', 'true') == 'true') do |browser|
        @page = browser.new_page(baseURL: Capybara.current_session.server.base_url)
        errors = []
        page.on('pageerror', ->(error) { errors << error.message })
        page.on('console', ->(message) { errors << message.text if message.type == 'error' })

        example.run

        if example.exception
          screenshot = Pathname(Capybara.save_path || 'tmp/screenshots')
                       .join("#{example.full_description.parameterize(separator: '_')}.png")
          page.screenshot(path: screenshot.to_s, fullPage: true)
          RSpec.configuration.reporter.message("[Screenshot Image]: #{screenshot}")
        else
          expect(errors).to eq([])
        end
      end
    end
  end
end
