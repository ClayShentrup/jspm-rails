# frozen_string_literal: true

require 'capybara/rspec'

# Request specs read the response through Capybara, as a page.
module CapybaraPage
  def page
    Capybara.string(response.body)
  end
end

RSpec.configure do |config|
  config.include(Capybara::RSpecMatchers, type: :request)
  config.include(CapybaraPage, type: :request)
end

Capybara.server = :puma, { Silent: true }
