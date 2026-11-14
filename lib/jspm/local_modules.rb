# frozen_string_literal: true

module Jspm
  # The modules Propshaft serves from the app and from engines. Each one is
  # importable by its asset name without the extension, the way importmap-rails
  # pins work: 'controllers/hello_controller', or 'controllers' for
  # controllers/index.js.
  #
  # config/importmap.json names these files as `asset:` plus their logical
  # path, so the map reads the same on every machine.
  class LocalModules
    EXTENSIONS = %w[.js .mjs].freeze
    SCHEME = 'asset:'
    private_constant :EXTENSIONS, :SCHEME

    LocalModule =
      Data.define(:logical_path, :path) do
        def asset_name
          "#{SCHEME}#{logical_path}"
        end

        def pins
          name = logical_path.delete_suffix(File.extname(logical_path))
          index = name.delete_suffix('/index') if name.end_with?('/index')
          [name, *index].map { |pin| [pin, path] }
        end
      end
    private_constant :LocalModule

    class << self
      def find(asset_paths:)
        new(modules: asset_paths.flat_map { |directory| directory_modules(directory) })
      end

      private

      def directory_modules(directory)
        files = directory.glob('**/*').select { |file| EXTENSIONS.include?(file.extname) }
        files.map do |file|
          logical_path = file.relative_path_from(directory).to_s
          LocalModule.new(logical_path:, path: file.to_s)
        end
      end
    end

    def initialize(modules:)
      @modules = modules
    end

    def pins
      modules.flat_map(&:pins).to_h
    end

    # A local file becomes its asset name. A local directory, the key of a
    # scope, becomes the asset root, where every local module is served. A
    # jspm.io URL stays as it is.
    def localize(target)
      case target
      when %r{\A/(?:.*/)?\z} then SCHEME
      when %r{\A/} then modules_by_path.fetch(target).asset_name
      else target
      end
    end

    private

    attr_reader :modules

    def modules_by_path
      modules.to_h { |local_module| [local_module.path, local_module] }
    end
  end
end
