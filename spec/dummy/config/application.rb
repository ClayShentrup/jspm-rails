# frozen_string_literal: true

require 'action_controller/railtie'
require 'action_view/railtie'
require 'jspm-rails'
require 'propshaft'
require 'rails'

module Dummy
  # Lets the system specs serve assets from a second origin, the way a CDN
  # does. Browsers load cross-origin modules and fonts only with this header.
  class CrossOriginAssets
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      [status, headers.merge('access-control-allow-origin' => '*'), body]
    end
  end

  class Application < Rails::Application
    config.load_defaults(8.1)
    config.root = File.expand_path('..', __dir__)
    config.eager_load = false
    config.secret_key_base = 'dummy'
    config.logger = Logger.new(nil)
    config.middleware.insert_before(ActionDispatch::Executor, CrossOriginAssets)
  end
end
