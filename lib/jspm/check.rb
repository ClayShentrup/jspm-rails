# frozen_string_literal: true

require 'json'

module Jspm
  # Traces again without writing anything, and reports whether
  # config/importmap.json and vendor/jspm match what an install would produce.
  class Check
    def self.call(output:, root:)
      lockfile = Lockfile.read(root)
      trace = Trace.call(lockfile:, root:)
      new(output:, root:, trace:).call
    end

    def initialize(output:, root:, trace:)
      @output = output
      @root = root
      @trace = trace
    end

    def call
      written = written?
      missing = missing_modules
      report('stale', Paths::IMPORT_MAP) unless written
      missing.each { |path| report('missing', path) }

      up_to_date = written && missing.empty?
      if up_to_date
        report('ok', 'nothing to install')
      else
        report('run', 'bin/rails jspm:install')
      end
      up_to_date
    end

    private

    attr_reader :output, :root, :trace

    def written?
      import_map_file = root.join(Paths::IMPORT_MAP)
      import_map_file.exist? && JSON.parse(import_map_file.read) == trace.import_map
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
