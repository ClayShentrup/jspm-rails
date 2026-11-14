# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'net/http'

module Jspm
  # Vendors every module the trace reaches from jspm.io, and writes
  # config/importmap.json.
  class Install
    SOURCE_MAP = %r{//# sourceMappingURL=(?<path>\S+\.map)\s*\z}
    PACKAGE_URL = %r{\Ahttps://ga\.jspm\.io/npm:(?<name>(?:@[^/]+/)?[^@/]+)@(?<version>[^/]+)/}
    private_constant :PACKAGE_URL, :SOURCE_MAP

    def self.call(asset_paths:, output:, root:)
      lockfile = Lockfile.read(root)
      trace = Trace.call(asset_paths:, lockfile:, root:)
      new(lockfile:, output:, root:, trace:).call
    end

    def initialize(lockfile:, output:, root:, trace:)
      @lockfile = lockfile
      @output = output
      @root = root
      @trace = trace
    end

    def call
      vendor_dir = root.join(Paths::VENDOR)
      FileUtils.rm_rf(vendor_dir)
      cdn = URI(Paths::CDN)
      cdn_urls = trace.cdn_urls
      Net::HTTP.start(cdn.host, cdn.port, use_ssl: true) { |http| download_all(http, cdn_urls, vendor_dir) }
      root.join(Paths::IMPORT_MAP).write("#{JSON.pretty_generate(trace.import_map)}\n")

      report('traced', Paths::ENTRY_PATH)
      report('vendored', "#{cdn_urls.size} modules from ga.jspm.io")
      report('wrote', Paths::IMPORT_MAP)
      warn_about_versions
    end

    private

    attr_reader :lockfile, :output, :root, :trace

    def download_all(http, urls, vendor_dir)
      urls.each { |url| download(http, url, vendor_dir) }
    end

    def download(http, url, vendor_dir)
      body = http.get(URI(url).path).tap(&:value).body
      file = vendor_dir.join(Paths.logical(url))
      file.dirname.mkpath
      file.binwrite(body)
      source_maps = body.scan(SOURCE_MAP).map { |(path)| URI.join(url, path).to_s }
      download_all(http, source_maps, vendor_dir)
    end

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
          "#{name}: package-lock.json has #{versions.join(' and ')}, " \
          "and the import map uses #{traced.fetch(name)} everywhere"
        )
      end
    end

    def report(status, message)
      output.puts(format('%<status>12s  %<message>s', message:, status:))
    end
  end
end
