# frozen_string_literal: true

module Jspm
  # The stylesheets, fonts and images in the node_modules directories the app
  # names in config.jspm.asset_directories, and where each one is vendored.
  module Assets
    EXTENSIONS = %w[
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
    private_constant :EXTENSIONS

    class << self
      # Each copy is a pair: the file in node_modules, and its vendored path.
      def copies(directories:, root:)
        directories.flat_map { |directory| directory_copies(directory, root) }
      end

      private

      def directory_copies(directory, root)
        source_dir = root.join('node_modules', directory)
        vendor_dir = root.join(Paths::VENDOR, directory)
        files =
          source_dir.glob('**/*').select do |file|
            EXTENSIONS.include?(file.extname.downcase)
          end
        files.map do |file|
          relative_path = file.relative_path_from(source_dir)
          [file, vendor_dir.join(relative_path)]
        end
      end
    end
  end
end
