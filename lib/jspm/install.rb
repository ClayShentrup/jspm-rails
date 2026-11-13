# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'net/http'
require 'open3'

module Jspm
  class Error < StandardError
  end

  # Traces app/javascript/application.js, vendors every module it reaches from
  # jspm.io at the versions in package-lock.json, copies the stylesheets, fonts
  # and images of each npm dependency, and writes config/importmap.json.
  class Install
    ASSET_EXTENSIONS = %w[
      .avif
      .css
      .eot
      .gif
      .jpeg
      .jpg
      .otf
      .png
      .svg
      .ttf
      .webp
      .woff
      .woff2
    ].freeze
    SOURCE_MAP = %r{//# sourceMappingURL=(?<path>\S+\.map)\s*\z}
    PACKAGE_URL = %r{\Ahttps://ga\.jspm\.io/npm:(?<name>(?:@[^/]+/)?[^@/]+)@(?<version>[^/]+)/}
    TRACE_SCRIPT = File.expand_path('trace.mjs', __dir__)
    private_constant :ASSET_EXTENSIONS, :PACKAGE_URL, :SOURCE_MAP, :TRACE_SCRIPT

    def self.call(output:, root:)
      lockfile = JSON.parse(root.join('package-lock.json').read)
      packages =
        lockfile.fetch('packages').reject do |path, package|
          app = path.empty?
          dev = package.fetch('dev', false)
          app || dev
        end
      new(output:, packages:, root:).call
    end

    def initialize(output:, packages:, root:)
      @output = output
      @packages = packages
      @root = root
    end

    def call
      trace = trace_entry
      urls = trace.fetch('staticDeps') + trace.fetch('dynamicDeps')
      FileUtils.rm_rf(vendor_dir)
      modules = vendor_modules(urls)
      assets = copy_assets
      write_import_map(trace)

      report('traced', Paths::ENTRY_PATH)
      report('vendored', "#{modules} modules from ga.jspm.io")
      report('copied', "#{assets} assets from node_modules")
      report('wrote', 'config/importmap.json')
      warn_about_versions(urls)
    end

    private

    attr_reader :output, :packages, :root

    def trace_entry
      input = JSON.generate(entry: Paths::ENTRY_PATH, resolutions:, root: root.to_s)
      json, status = Open3.capture2('node', TRACE_SCRIPT, stdin_data: input)
      raise(Error, "tracing #{Paths::ENTRY_PATH} failed") unless status.success?

      JSON.parse(json)
    end

    def resolutions
      top_level_packages.to_h { |path, package| [package_name(path), package.fetch('version')] }
    end

    def top_level_packages
      packages.select { |path, _package| top_level?(path) }
    end

    def top_level?(path)
      path.scan('node_modules/').one?
    end

    def package_name(path)
      path.split('node_modules/').last
    end

    def vendor_modules(urls)
      cdn_urls = urls.select { |url| url.start_with?(Paths::CDN) }
      cdn = URI(Paths::CDN)
      Net::HTTP.start(cdn.host, cdn.port, use_ssl: true) do |http|
        cdn_urls.each { |url| download(http, url) }
      end
      cdn_urls.size
    end

    def download(http, url)
      response = http.get(URI(url).path)
      response.value
      file = vendor_dir.join(Paths.logical(url))
      file.dirname.mkpath
      file.binwrite(response.body)
      source_maps = response.body.scan(SOURCE_MAP).map { |(path)| URI.join(url, path).to_s }
      source_maps.each { |source_map| download(http, source_map) }
    end

    def copy_assets
      copies = top_level_packages.keys.flat_map { |path| asset_copies(path) }
      copies.each do |file, target|
        target.dirname.mkpath
        FileUtils.cp(file, target)
      end
      copies.size
    end

    def asset_copies(path)
      package_dir = root.join(path)
      name = package_name(path)
      files =
        package_dir.glob('**/*').select do |file|
          ASSET_EXTENSIONS.include?(file.extname.downcase)
        end
      files.map do |file|
        relative_path = file.relative_path_from(package_dir)
        [file, vendor_dir.join(name, relative_path)]
      end
    end

    def write_import_map(trace)
      import_map = trace.fetch('map').merge('preload' => trace.fetch('preload'))
      root.join('config/importmap.json').write("#{JSON.pretty_generate(import_map)}\n")
    end

    def warn_about_versions(urls)
      traced = traced_packages(urls)
      versions_by_name =
        traced.to_h do |name, version|
          [name, (nested_versions(name) | [version]).sort]
        end
      conflicts = versions_by_name.select { |_name, versions| versions.many? }
      conflicts.each do |name, versions|
        report(
          'warn',
          "#{name}: package-lock.json has #{versions.join(' and ')}, " \
          "and the import map uses #{traced.fetch(name)} everywhere"
        )
      end
      (traced.keys - resolutions.keys).each do |name|
        report('warn', "#{name} isn't in package-lock.json, so its version isn't locked")
      end
    end

    def traced_packages(urls)
      urls.grep(PACKAGE_URL) { |url| url.match(PACKAGE_URL).values_at(:name, :version) }
          .sort
          .to_h
    end

    def nested_versions(name)
      packages.filter_map do |path, package|
        same_name = package_name(path) == name
        nested = !top_level?(path)
        package.fetch('version') if same_name && nested
      end
    end

    def vendor_dir
      root.join('vendor/jspm')
    end

    def report(status, message)
      output.puts(format('%<status>12s  %<message>s', message:, status:))
    end
  end
end
