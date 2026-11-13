# frozen_string_literal: true

require_relative 'lib/jspm/version'

Gem::Specification.new do |spec|
  spec.name = 'jspm-rails'
  spec.version = Jspm::VERSION
  spec.authors = ['Clay Shentrup']
  spec.summary = 'Import maps for Rails, built by jspm'
  spec.description = <<~DESCRIPTION
    Traces app/javascript/application.js with jspm, vendors every module it reaches from jspm.io,
    and serves them through Propshaft. Versions lock in jspm's import map, or in package-lock.json for
    packages installed with npm. No bundler, no build step.
  DESCRIPTION
  spec.homepage = 'https://github.com/ClayShentrup/jspm-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'
  spec.metadata = {
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => spec.homepage
  }
  spec.files = Dir['lib/**/*', 'CHANGELOG.md', 'LICENSE', 'README.md']
  spec.add_dependency('propshaft', '>= 1.1')
  spec.add_dependency('railties', '>= 8.0')
end
