# frozen_string_literal: true

require 'json'

module Jspm
  # Reads Yarn 1's yarn.lock. Unlike package-lock.json, it records neither
  # where each package sits in node_modules nor which ones only development
  # needs. A package locked at one version is the top-level one. When Yarn
  # locked several versions, the one node_modules holds at its top level is.
  # A package is a development one unless the dependencies in package.json
  # reach it.
  module YarnLock
    Entry =
      Data.define(:dependencies, :name, :specs, :version) do
        def keyed_by_spec
          specs.map { |spec| [spec, self] }
        end

        def dependency_specs
          dependencies.map { |name, range| "#{name}@#{range}" }
        end
      end
    private_constant :Entry

    DEPENDENCY = /\A {4}"?(?<name>[^"\s]+)"? "?(?<range>[^"]+)"?\z/
    private_constant :DEPENDENCY

    class << self
      def packages(root)
        entries = parse(root.join('yarn.lock').read)
        manifest = JSON.parse(root.join('package.json').read)
        runtime = reachable(manifest.fetch('dependencies', {}), entries)
        locked_once = entries.map(&:name).tally.select { |_name, count| count == 1 }
                             .keys
        entries.map do |entry|
          name = entry.name
          version = entry.version
          path = "node_modules/#{name}"
          top_level = locked_once.include?(name) || installed_version(root.join(path)) == version
          { dev: !runtime.include?(entry), name:, path:, top_level:, version: }
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
        specs = header.delete_suffix(':').split(', ').map { |spec| spec.delete('"') }
        name = specs.first.rpartition('@').first
        version = body.find { |line| line.start_with?('  version ') }[/"(.*)"/, 1]
        dependencies =
          body.grep(DEPENDENCY) do |line|
            line.match(DEPENDENCY).values_at(:name, :range)
          end
        Entry.new(dependencies:, name:, specs:, version:)
      end

      def reachable(roots, entries)
        by_spec = entries.flat_map(&:keyed_by_spec).to_h
        queue = roots.map { |name, range| "#{name}@#{range}" }
        seen = Set.new
        until queue.empty?
          entry = by_spec.fetch(queue.shift)
          next unless seen.add?(entry)

          queue.concat(entry.dependency_specs)
        end
        seen
      end
    end
  end
end
