# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'reek/rake/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Reek::Rake::Task.new do |task|
  task.source_files = '{lib,spec}/**/*.rb'
end

task default: %i[rubocop reek spec]
