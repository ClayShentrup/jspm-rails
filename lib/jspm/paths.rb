# frozen_string_literal: true

module Jspm
  # Translates the URLs jspm writes into Propshaft logical paths.
  #
  # jspm.io files are vendored under vendor/jspm/ga.jspm.io/npm/, and the app's
  # own modules are served from app/javascript. Both directories are on the
  # asset load path, so each URL maps to exactly one logical path.
  module Paths
    CDN = 'https://ga.jspm.io/'
    ENTRY = 'application.js'
    LOCAL = './app/javascript/'
    ENTRY_PATH = "#{LOCAL}#{ENTRY}".freeze
    IMPORT_MAP = 'config/importmap.json'
    VENDOR = 'vendor/jspm'
    public_constant :CDN, :ENTRY, :ENTRY_PATH, :IMPORT_MAP, :LOCAL, :VENDOR

    def self.logical(url)
      return url.delete_prefix('https://').sub('/npm:', '/npm/') if url.start_with?(CDN)
      return '' if url == './'

      url.delete_prefix(LOCAL)
    end
  end
end
