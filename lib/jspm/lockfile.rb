# frozen_string_literal: true

require 'json'

module Jspm
  # The packages npm or Yarn installed, as package-lock.json or yarn.lock
  # records them.
  class Lockfile
    Package =
      Data.define(:name, :top_level, :version) do
        def resolution
          [name, version]
        end

        def nested?(other_name)
          !top_level && name == other_name
        end
      end
    private_constant :Package

    class << self
      def read(root)
        yarn = root.join('yarn.lock').exist?
        file_name = yarn ? 'yarn.lock' : 'package-lock.json'
        packages = yarn ? YarnLock.packages(root) : npm_packages(root)
        new(file_name:, packages: packages.map { |package| Package.new(**package) })
      end

      private

      def npm_packages(root)
        json = JSON.parse(root.join('package-lock.json').read)
        installed = json.fetch('packages').reject { |path, _package| path.empty? }
        installed.map do |path, package|
          name = path.split('node_modules/').last
          top_level = path.scan('node_modules/').one?
          version = package.fetch('version')
          { name:, top_level:, version: }
        end
      end
    end

    def initialize(file_name:, packages:)
      @file_name = file_name
      @packages = packages
    end

    attr_reader :file_name

    def resolutions
      packages.select(&:top_level).to_h(&:resolution)
    end

    def nested_versions(name)
      nested = packages.select { |package| package.nested?(name) }
      nested.map(&:version)
    end

    private

    attr_reader :packages
  end
end
