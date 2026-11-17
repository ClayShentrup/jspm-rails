# frozen_string_literal: true

require 'net/http'

module Jspm
  # Downloads modules from jspm.io, along with the source maps they name. Each
  # file is keyed by the path it is vendored at.
  module Fetch
    SOURCE_MAP = %r{//# sourceMappingURL=(?<path>\S+\.map)\s*\z}
    private_constant :SOURCE_MAP

    class << self
      def call(urls)
        cdn = URI(Paths::CDN)
        pairs = Net::HTTP.start(cdn.host, cdn.port, use_ssl: true) { |http| fetch_all(http, urls) }
        pairs.to_h
      end

      private

      def fetch_all(http, urls)
        urls.flat_map do |url|
          body = http.get(URI(url).path).tap(&:value).body
          path = File.join(Paths::VENDOR, Paths.logical(url))
          [[path, body], *fetch_all(http, source_maps(url, body))]
        end
      end

      def source_maps(url, body)
        body.scan(SOURCE_MAP).map { |(path)| URI.join(url, path).to_s }
      end
    end
  end
end
