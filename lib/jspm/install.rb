# frozen_string_literal: true

require 'fileutils'
require 'json'

module Jspm
  # Vendors every module the trace reaches from jspm.io, and writes
  # config/importmap.json.
  class Install
    PACKAGE_URL = %r{\Ahttps://ga\.jspm\.io/npm:(?<name>(?:@[^/]+/)?[^@/]+)@(?<version>[^/]+)/}
    private_constant :PACKAGE_URL

    def self.call(asset_paths:, output:, root:)
      lockfile = Lockfile.read(root)
      trace = Trace.call(asset_paths:, lockfile:, root:)
      vendored_files = Fetch.call(trace.cdn_urls)
      new(lockfile:, output:, root:, trace:, vendored_files:).call
    end

    def initialize(lockfile:, output:, root:, trace:, vendored_files:)
      @lockfile = lockfile
      @output = output
      @root = root
      @trace = trace
      @vendored_files = vendored_files
    end

    def call
      FileUtils.rm_rf(root.join(Paths::VENDOR))
      vendored_files.each do |path, body|
        file = root.join(path)
        file.dirname.mkpath
        file.binwrite(body)
      end
      root.join(Paths::IMPORT_MAP).write("#{JSON.pretty_generate(trace.import_map)}\n")

      report('traced', Paths::ENTRY_PATH)
      report('vendored', "#{trace.cdn_urls.size} modules from ga.jspm.io")
      report('wrote', Paths::IMPORT_MAP)
      warn_about_versions
    end

    private

    attr_reader :lockfile, :output, :root, :trace, :vendored_files

    def warn_about_versions
      packages =
        trace.urls.grep(PACKAGE_URL) do |url|
          url.match(PACKAGE_URL).values_at(:name, :version)
        end
      traced = packages.sort.to_h
      versions_by_name =
        traced.to_h { |name, version| [name, (lockfile.nested_versions(name) | [version]).sort] }
      conflicts = versions_by_name.select { |_name, versions| versions.many? }
      conflicts.each do |name, versions|
        report(
          'warn',
          "#{name}: #{lockfile.file_name} has #{versions.join(' and ')}, " \
          "and the import map uses #{traced.fetch(name)} everywhere"
        )
      end
    end

    def report(status, message)
      output.puts(format('%<status>12s  %<message>s', message:, status:))
    end
  end
end
