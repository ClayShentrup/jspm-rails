# frozen_string_literal: true

require 'json'

module Jspm
  # Reads Yarn 1's yarn.lock. Unlike package-lock.json, it doesn't record
  # where each package sits in node_modules. A package locked at one version
  # is the top-level one. When Yarn locked several versions, the one
  # node_modules holds at its top level is.
  module YarnLock
    Entry = Data.define(:name, :version)
    private_constant :Entry

    class << self
      def packages(root)
        entries = parse(root.join('yarn.lock').read)
        counts = entries.map(&:name).tally
        entries.map do |entry|
          name = entry.name
          version = entry.version
          locked_once = counts.fetch(name) == 1
          installed = installed_version(root.join('node_modules', name)) == version
          { name:, top_level: locked_once || installed, version: }
        end
      end

      private

      def installed_version(package_dir)
        manifest = package_dir.join('package.json')
        JSON.parse(manifest.read).fetch('version') if manifest.exist?
      end

      def parse(text)
        blocks =
          text.split(/\n{2,}/).reject do |block|
            block.start_with?('#') || block.strip.empty?
          end
        blocks.map { |block| parse_entry(block) }
      end

      def parse_entry(block)
        header, *body = block.lines(chomp: true)
        spec = header.delete_suffix(':').split(', ').first.delete('"')
        version = body.find { |line| line.start_with?('  version ') }[/"(.*)"/, 1]
        Entry.new(name: spec.rpartition('@').first, version:)
      end
    end
  end
end
