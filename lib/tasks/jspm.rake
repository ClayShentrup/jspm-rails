# frozen_string_literal: true

namespace :jspm do
  desc 'Vendor what app/javascript/application.js imports, at the versions in package-lock.json'
  task :install do
    Jspm::Install.call(output: $stdout, root: Rails.root)
  end
end
