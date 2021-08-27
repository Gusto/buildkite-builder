# frozen_string_literal: true

require 'set'
require 'pathname'

module Buildkite
  module Builder
    class Manifest::Rule
      GLOB_OPTIONS = File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB

      attr_reader :exclude
      attr_reader :glob

      def initialize(root, pattern)
        @root = Pathname.new(root)
        @exclude = false
        @glob = @root

        if pattern[0] == '!'
          @exclude = true
          pattern = pattern[1..-1]
        end

        if pattern.start_with?('/')
          pattern = pattern[1..-1]
        else
          @glob = @glob.join('**')
        end

        @glob = @glob.join(pattern).to_s
      end

      def files
        @files ||= begin
          matched = Dir.glob(glob, GLOB_OPTIONS)
          matched.map! { |file| Pathname.new(file) }
          matched.reject!(&:directory?)
          matched.map! { |file| file.relative_path_from(Builder.root) }
          Set.new(matched.sort!)
        end
      end

      def match?(file)
        file = Pathname.new(file)
        file = @root.join(file) unless file.absolute?

        File.fnmatch?(glob, file.to_s, GLOB_OPTIONS)
      end
    end
  end
end
