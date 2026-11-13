# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
require_relative 'support/dummy_install'
require 'capybara/rspec'
require 'rspec/rails'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.infer_spec_type_from_file_location!
  config.order = :random
  config.before(:suite) { DummyInstall.output }
  config.before(type: :system) { driven_by(:selenium, using: :headless_chrome) }
end
