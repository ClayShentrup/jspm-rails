# frozen_string_literal: true

require 'json'

module Jspm
  # Traces again without writing anything, and reports whether
  # config/importmap.json and vendor/jspm match what an install would produce,
  # byte for byte.
  class Check
    def self.call(asset_paths:, output:, root:)
      lockfile = Lockfile.read(root)
      trace = Trace.call(asset_paths:, lockfile:, root:)
      vendored_files = Fetch.call(trace.cdn_urls)
      new(output:, root:, trace:, vendored_files:).call
    end

    def initialize(output:, root:, trace:, vendored_files:)
      @output = output
      @root = root
      @trace = trace
      @vendored_files = vendored_files
    end

    def call
      written = written?
      drifted = drifted_files
      report('stale', Paths::IMPORT_MAP) unless written
      drifted.each { |path, status| report(status, path) }

      up_to_date = written && drifted.empty?
      if up_to_date
        report('ok', 'nothing to install')
      else
        report('run', 'bin/rails jspm:install')
      end
      up_to_date
    end

    private

    attr_reader :output, :root, :trace, :vendored_files

    def written?
      import_map_file = root.join(Paths::IMPORT_MAP)
      import_map_file.exist? && JSON.parse(import_map_file.read) == trace.import_map
    end

    def drifted_files
      statuses = vendored_files.to_h { |path, body| [path, drift(root.join(path), body)] }
      statuses.compact
    end

    def drift(file, body)
      return 'missing' unless file.file?

      'changed' unless file.binread == body
    end

    def report(status, message)
      output.puts(format('%<status>12s  %<message>s', message:, status:))
    end
  end
end
