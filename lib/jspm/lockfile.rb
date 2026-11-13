# frozen_string_literal: true

require 'json'

module Jspm
  # The packages npm installed, as package-lock.json records them.
  class Lockfile
    Package =
      Data.define(:dev, :name, :path, :top_level, :version) do
        def browser?
          top_level && !dev
        end

        def resolution
          [name, version]
        end

        def nested?(other_name)
          !top_level && name == other_name
        end
      end
    private_constant :Package

    def self.read(root)
      json = JSON.parse(root.join('package-lock.json').read)
      installed = json.fetch('packages').reject { |path, _package| path.empty? }
      packages =
        installed.map do |path, package|
          name = path.split('node_modules/').last
          top_level = path.scan('node_modules/').one?
          version = package.fetch('version')
          dev = package.fetch('dev', false)
          Package.new(dev:, name:, path:, top_level:, version:)
        end
      new(packages:)
    end

    def initialize(packages:)
      @packages = packages
    end

    def resolutions
      packages.select(&:top_level).to_h(&:resolution)
    end

    def browser_packages
      packages.select(&:browser?)
    end

    def nested_versions(name)
      nested = packages.select { |package| package.nested?(name) }
      nested.map(&:version)
    end

    private

    attr_reader :packages
  end
end
