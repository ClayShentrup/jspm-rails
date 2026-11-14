# frozen_string_literal: true

namespace :jspm do
  desc 'Vendor what app/javascript/application.js imports, and write config/importmap.json'
  task install: :environment do
    Jspm::Install.call(
      asset_directories: Rails.application.config.jspm.asset_directories,
      asset_paths: Rails.application.config.assets.paths,
      output: $stdout,
      root: Rails.root
    )
  end

  desc 'Fail if config/importmap.json or vendor/jspm is out of date'
  task check: :environment do
    passed = Jspm::Check.call(
      asset_directories: Rails.application.config.jspm.asset_directories,
      asset_paths: Rails.application.config.assets.paths,
      output: $stdout,
      root: Rails.root
    )
    abort unless passed
  end
end
