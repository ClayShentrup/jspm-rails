# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# Copies a fixture app into a fresh directory, so each example installs into
# a clean one. node_modules is linked rather than copied.
module FixtureApp
  def self.copy(name)
    source = Pathname(File.expand_path("../fixtures/#{name}", __dir__))
    directory = Pathname(Dir.mktmpdir(name))
    files = source.children.reject { |child| child.basename.to_s == 'node_modules' }
    FileUtils.cp_r(files, directory)
    directory.join('node_modules').make_symlink(source.join('node_modules'))
    directory
  end
end
