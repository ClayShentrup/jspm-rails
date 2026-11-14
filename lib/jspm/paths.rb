# frozen_string_literal: true

module Jspm
  # Translates the URLs in config/importmap.json into Propshaft logical paths.
  #
  # jspm.io files are vendored under vendor/jspm/ga.jspm.io/npm/, and local
  # modules are written as `asset:` plus their logical path.
  module Paths
    CDN = 'https://ga.jspm.io/'
    ENTRY = 'application.js'
    LOCAL = './app/javascript/'
    ENTRY_PATH = "#{LOCAL}#{ENTRY}".freeze
    IMPORT_MAP = 'config/importmap.json'
    VENDOR = 'vendor/jspm'
    public_constant :CDN, :ENTRY, :ENTRY_PATH, :IMPORT_MAP, :VENDOR
    private_constant :LOCAL

    def self.logical(url)
      return url.delete_prefix('https://').sub('/npm:', '/npm/') if url.start_with?(CDN)

      url.delete_prefix('asset:')
    end
  end
end
