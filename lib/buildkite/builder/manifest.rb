# frozen_string_literal: true

require 'digest/md5'
require 'pathname'
require 'sorted_set'

module Buildkite
  module Builder
    class Manifest
      autoload :Rule, File.expand_path('manifest/rule', __dir__)

      class << self
        def resolve(root, patterns)
          new(root, Array(patterns)).modified?
        end

        def manifests
          @manifests ||= {}
        end

        def [](name)
          manifests[name.to_s]
        end

        def []=(name, manifest)
          name = name.to_s
          if manifests.key?(name)
            raise ArgumentError, "manifest #{name} already exists"
          end

          manifests[name] = manifest
        end
      end

      attr_reader :root

      def initialize(root, patterns)
        @root = Pathname.new(root)
        @root = Buildkite::Builder.root.join(@root) unless @root.absolute?
        @patterns = patterns.map(&:to_s)
      end

      def modified?
        # DO NOT intersect FileResolver with manifest files. If the manifest is
        # large, the operation can be expensive. It's always cheaper to loop
        # through the changed files and compare them against the rules.
        unless defined?(@modified)
          @modified = FileResolver.resolve.modified_files.any? do |file|
            file = Buildkite::Builder.root.join(file)
            inclusion_rules.any? { |rule| rule.match?(file) } &&
              exclusion_rules.none? { |rule| rule.match?(file) }
          end
        end

        @modified
      end

      def files
        @files ||= inclusion_rules.map(&:files).reduce(SortedSet.new, :merge) - exclusion_rules.map(&:files).reduce(SortedSet.new, :merge)
      end

      def digest
        @digest ||= begin
          digests = files.map { |file| Digest::MD5.file(Buildkite::Builder.root.join(file)).hexdigest }
          Digest::MD5.hexdigest(digests.join)
        end
      end

      private

      def rules
        @rules ||= @patterns.each_with_object([]) do |pattern, rules|
          pattern = pattern.strip
          unless pattern.match?(/\A(#|\z)/)
            rules << Rule.new(root, pattern)
          end
        end
      end

      def inclusion_rules
        @inclusion_rules ||= rules.reject(&:exclude)
      end

      def exclusion_rules
        @exclusion_rules ||= rules.select(&:exclude)
      end
    end
  end
end
