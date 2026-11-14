# frozen_string_literal: true

require 'fileutils'
require 'json'

module Jspm
  # Traces again without writing anything, and reports whether
  # config/importmap.json and vendor/jspm match what an install would produce.
  class Check
    def self.call(asset_directories:, asset_paths:, output:, root:)
      lockfile = Lockfile.read(root)
      trace = Trace.call(asset_paths:, lockfile:, root:)
      new(asset_directories:, output:, root:, trace:).call
    end

    def initialize(asset_directories:, output:, root:, trace:)
      @asset_directories = asset_directories
      @output = output
      @root = root
      @trace = trace
    end

    def call
      written = written?
      missing = missing_modules
      stale_assets = stale_asset_paths
      report('stale', Paths::IMPORT_MAP) unless written
      missing.each { |path| report('missing', path) }
      stale_assets.each { |path| report('stale', path) }

      up_to_date = written && missing.empty? && stale_assets.empty?
      if up_to_date
        report('ok', 'nothing to install')
      else
        report('run', 'bin/rails jspm:install')
      end
      up_to_date
    end

    private

    attr_reader :asset_directories, :output, :root, :trace

    def written?
      import_map_file = root.join(Paths::IMPORT_MAP)
      import_map_file.exist? && JSON.parse(import_map_file.read) == trace.import_map
    end

    def stale_asset_paths
      copies = Assets.copies(directories: asset_directories, root:)
      stale =
        copies.reject do |source, target|
          target.file? && FileUtils.compare_file(source, target)
        end
      stale.map { |_source, target| target.relative_path_from(root).to_s }
    end

    def missing_modules
      vendored = trace.cdn_urls.map { |url| File.join(Paths::VENDOR, Paths.logical(url)) }
      vendored.reject { |path| root.join(path).file? }
    end

    def report(status, message)
      output.puts(format('%<status>12s  %<message>s', message:, status:))
    end
  end
end
