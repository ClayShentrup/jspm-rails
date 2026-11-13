# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
require 'rspec/rails'
require_relative 'support/capybara'
require_relative 'support/dummy_install'
require_relative 'support/fixture_app'
require_relative 'support/playwright'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.infer_spec_type_from_file_location!
  config.order = :random
  config.before(:suite) { DummyInstall.output }
end
