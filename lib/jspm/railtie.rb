# frozen_string_literal: true

require 'rails/railtie'

module Jspm
  # Serves the app's modules and the vendored dependencies through Propshaft.
  class Railtie < Rails::Railtie
    # jspm.io publishes many packages' modules as .mjs, and browsers only run
    # a module script served with a JavaScript MIME type.
    initializer 'jspm.mime_type' do
      Mime::Type.register_alias('text/javascript', :mjs)
    end

    initializer 'jspm.assets' do |app|
      app.config.assets.paths.push(app.root.join('app/javascript'), app.root.join('vendor/jspm'))
    end

    initializer 'jspm.helper' do
      ActiveSupport.on_load(:action_view) { include Helper }
    end

    rake_tasks do
      load File.expand_path('../tasks/jspm.rake', __dir__)
    end
  end
end
