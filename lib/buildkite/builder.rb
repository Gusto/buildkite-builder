# frozen_string_literal: true

require 'bundler'
require 'logger'
require 'pathname'

module Buildkite
  module Builder
    VERSION = '1.0.0.beta.2'

    autoload :Commands, File.expand_path('builder/commands', __dir__)
    autoload :Definition, File.expand_path('builder/definition', __dir__)
    autoload :FileResolver, File.expand_path('builder/file_resolver', __dir__)
    autoload :Github, File.expand_path('builder/github', __dir__)
    autoload :Loaders, File.expand_path('builder/loaders', __dir__)
    autoload :LoggingUtils, File.expand_path('builder/logging_utils', __dir__)
    autoload :Manifest, File.expand_path('builder/manifest', __dir__)
    autoload :Processors, File.expand_path('builder/processors', __dir__)
    autoload :Rainbow, File.expand_path('builder/rainbow', __dir__)
    autoload :Runner, File.expand_path('builder/runner', __dir__)

    BUILDKITE_DIRECTORY_NAME = '.buildkite/'

    class << self
      def root(start_path: Dir.pwd, reset: false)
        @root = nil if reset
        @root ||= find_buildkite_directory(start_path)
      end

      def find_buildkite_directory(start_path)
        path = Pathname.new(start_path)
        until path.join(BUILDKITE_DIRECTORY_NAME).exist? && path.join(BUILDKITE_DIRECTORY_NAME).directory?
          raise "Unable to find #{BUILDKITE_DIRECTORY_NAME} from #{start_path}" if path == path.parent

          path = path.parent
        end
        path.expand_path
      end

      def expand_path(path)
        path = Pathname.new(path)
        path.absolute? ? path : root.join(path)
      end

      def template(&block)
        Definition::Template.new(&block) if block_given?
      end

      def pipeline(&block)
        Definition::Pipeline.new(&block) if block_given?
      end
    end
  end
end
