# frozen_string_literal: true

namespace :jspm do
  desc 'Vendor what app/javascript/application.js imports, and write config/importmap.json'
  task :install do
    Jspm::Install.call(output: $stdout, root: Rails.root)
  end

  desc 'Fail if config/importmap.json or vendor/jspm is out of date'
  task :check do
    abort unless Jspm::Check.call(output: $stdout, root: Rails.root)
  end
end
