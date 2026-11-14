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
        packages = root.join('yarn.lock').exist? ? YarnLock.packages(root) : npm_packages(root)
        new(packages: packages.map { |package| Package.new(**package) })
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

    def initialize(packages:)
      @packages = packages
    end

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
