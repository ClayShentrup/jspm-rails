# frozen_string_literal: true

module Jspm
  # The stylesheets, fonts and images of each npm dependency, and where each
  # one is vendored. devDependencies are build tools, so they stay out.
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
      def copies(lockfile:, root:)
        lockfile.browser_packages.flat_map { |package| package_copies(package, root) }
      end

      private

      def package_copies(package, root)
        package_dir = root.join(package.path)
        vendor_dir = root.join(Paths::VENDOR, package.name)
        files =
          package_dir.glob('**/*').select do |file|
            EXTENSIONS.include?(file.extname.downcase)
          end
        files.map do |file|
          relative_path = file.relative_path_from(package_dir)
          [file, vendor_dir.join(relative_path)]
        end
      end
    end
  end
end
