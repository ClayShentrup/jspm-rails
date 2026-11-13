# frozen_string_literal: true

require 'json'
require 'open3'

module Jspm
  class Error < StandardError
  end

  # What jspm's generator finds when it traces the app's entry module. The
  # previous import map locks versions, as in jspm, and package-lock.json's
  # versions override it.
  Trace =
    Data.define(:import_map, :urls) do
      def self.call(lockfile:, root:)
        import_map_file = root.join(Paths::IMPORT_MAP)
        locked = import_map_file.exist? ? JSON.parse(import_map_file.read).except('preload') : {}
        input = JSON.generate(
          entry: Paths::ENTRY_PATH,
          inputMap: locked,
          resolutions: lockfile.resolutions,
          root: root.to_s
        )
        script = File.expand_path('trace.mjs', __dir__)
        json, status = Open3.capture2('node', script, stdin_data: input)
        raise(Error, "tracing #{Paths::ENTRY_PATH} failed") unless status.success?

        result = JSON.parse(json)
        import_map = result.fetch('map').merge('preload' => result.fetch('preload'))
        urls = result.fetch('staticDeps') + result.fetch('dynamicDeps')
        new(import_map:, urls:)
      end

      def cdn_urls
        urls.select { |url| url.start_with?(Paths::CDN) }
      end
    end
  public_constant :Trace
end
