# frozen_string_literal: true

require 'json'
require 'open3'

module Jspm
  class Error < StandardError
  end

  # What jspm's generator finds when it traces the app's entry module. The
  # previous import map locks versions, as in jspm, and package-lock.json's
  # versions override it. Modules on the asset path are importable by name.
  Trace =
    Data.define(:import_map, :urls) do
      def self.call(asset_paths:, lockfile:, root:)
        vendor_dir = root.join(Paths::VENDOR)
        pathnames = asset_paths.map { |path| Pathname(path) }
        module_paths = pathnames.reject { |path| path == vendor_dir }
        local_modules = LocalModules.find(asset_paths: module_paths)
        resolutions = lockfile.resolutions
        # A package the app installed beats a gem's file of the same name, such
        # as actiontext's trix.js, so the app and its packages share one copy.
        pins = local_modules.pins.reject { |name, _path| resolutions.key?(name) }
        # Every app module is traced and named in the map, as importmap-rails
        # pins them, so code can import one by a name it computes, the way
        # stimulus-rails's eagerLoadControllersFrom does.
        app_dir = root.join('app/javascript').to_s
        app_modules = pins.select { |_name, path| path.start_with?(app_dir) }
                          .keys
        input = JSON.generate(
          entries: [Paths::ENTRY_PATH, *app_modules],
          inputMap: { imports: locked_versions(root).merge(pins), scopes: {} },
          resolutions:,
          root: root.to_s
        )
        script = File.expand_path('trace.mjs', __dir__)
        json, status = Open3.capture2('node', script, stdin_data: input)
        raise(Error, "tracing #{Paths::ENTRY_PATH} failed") unless status.success?

        from_trace(JSON.parse(json), local_modules)
      end

      # Every jspm.io module the previous map named, keyed by its specifier.
      # jspm keeps the versions of packages it finds there.
      def self.locked_versions(root)
        import_map_file = root.join(Paths::IMPORT_MAP)
        return {} unless import_map_file.exist?

        import_map = JSON.parse(import_map_file.read)
        specifiers = [import_map.fetch('imports'), *import_map.fetch('scopes', {}).values]
        specifiers.reduce(:merge).select { |_specifier, url| url.start_with?(Paths::CDN) }
      end

      def self.from_trace(result, local_modules)
        localize = local_modules.method(:localize)
        imports = result.fetch('imports').transform_values(&localize)
        scopes = localize_scopes(result.fetch('scopes'), localize)
        static = result.fetch('staticDeps').map(&localize)
        dynamic = result.fetch('dynamicDeps').map(&localize)
        new(
          import_map: { 'imports' => imports, 'scopes' => scopes, 'preload' => static },
          urls: static + dynamic
        )
      end

      # Every local directory becomes the asset root, so their scopes merge.
      def self.localize_scopes(scopes, localize)
        pairs =
          scopes.map do |scope, specifiers|
            [localize.call(scope), specifiers.transform_values(&localize)]
          end
        grouped = pairs.group_by(&:first)
        grouped.transform_values { |entries| entries.map(&:last).reduce(:merge) }
      end

      def cdn_urls
        urls.select { |url| url.start_with?(Paths::CDN) }
      end
    end
  public_constant :Trace
end
