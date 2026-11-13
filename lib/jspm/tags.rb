# frozen_string_literal: true

require 'json'

module Jspm
  # Renders config/importmap.json for the browser.
  #
  # Propshaft serves every file under a digested name, but a module's relative
  # imports name its siblings undigested. So the rendered map also sends each
  # undigested module URL to its digested one.
  class Tags
    MODULE_EXTENSIONS = %w[.css .js .mjs].freeze
    private_constant :MODULE_EXTENSIONS

    def self.call(view:)
      import_map = JSON.parse(Rails.root.join(Paths::IMPORT_MAP).read)
      load_path = Rails.application.assets.load_path
      entry_url = view.asset_path(Paths::ENTRY)
      digested_entry = load_path.find(Paths::ENTRY).digested_path.to_s
      prefix = entry_url.delete_suffix(digested_entry)
      new(entry_url:, import_map:, load_path:, prefix:, view:).call
    end

    def initialize(entry_url:, import_map:, load_path:, prefix:, view:)
      @entry_url = entry_url
      @import_map = import_map
      @load_path = load_path
      @prefix = prefix
      @view = view
    end

    def call
      nonce = view.content_security_policy_nonce
      tag = view.tag
      imports = asset_urls(import_map.fetch('imports'))
      json = ERB::Util.json_escape(JSON.generate(imports: imports.merge(digests), scopes:))
      preloads =
        import_map.fetch('preload').map do |url|
          href = asset_url(url)
          tag.link(href:, nonce:, rel: 'modulepreload')
        end
      import_map_tag = tag.script(
        json.html_safe,
        data: { turbo_track: 'reload' },
        nonce:,
        type: 'importmap'
      )
      entry_tag = tag.script(nonce:, src: entry_url, type: 'module')
      view.safe_join([import_map_tag, *preloads, entry_tag], "\n")
    end

    private

    attr_reader :entry_url, :import_map, :load_path, :prefix, :view

    def scopes
      import_map.fetch('scopes', {}).to_h do |scope, specifiers|
        ["#{prefix}#{Paths.logical(scope)}", asset_urls(specifiers)]
      end
    end

    def asset_urls(specifiers)
      specifiers.transform_values { |url| asset_url(url) }
    end

    def digests
      paths = load_path.assets.map { |asset| [asset.logical_path, asset.digested_path] }
      modules =
        paths.select do |logical_path, _digested_path|
          MODULE_EXTENSIONS.include?(logical_path.extname)
        end
      modules.to_h do |logical_path, digested_path|
        ["#{prefix}#{logical_path}", "#{prefix}#{digested_path}"]
      end
    end

    def asset_url(url)
      logical_path = Paths.logical(url)
      view.asset_path(logical_path)
    end
  end
end
