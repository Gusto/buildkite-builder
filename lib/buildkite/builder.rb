# frozen_string_literal: true

require 'pathname'

module Buildkite
  module Builder
    autoload :Commands, File.expand_path('builder/commands', __dir__)
    autoload :Group, File.expand_path('builder/group', __dir__)
    autoload :Pipeline, File.expand_path('builder/pipeline', __dir__)
    autoload :Definition, File.expand_path('builder/definition', __dir__)
    autoload :Data, File.expand_path('builder/data', __dir__)
    autoload :Dsl, File.expand_path('builder/dsl', __dir__)
    autoload :Extension, File.expand_path('builder/extension', __dir__)
    autoload :ExtensionManager, File.expand_path('builder/extension_manager', __dir__)
    autoload :Extensions, File.expand_path('builder/extensions', __dir__)
    autoload :FileResolver, File.expand_path('builder/file_resolver', __dir__)
    autoload :Github, File.expand_path('builder/github', __dir__)
    autoload :Loaders, File.expand_path('builder/loaders', __dir__)
    autoload :LoggingUtils, File.expand_path('builder/logging_utils', __dir__)
    autoload :Manifest, File.expand_path('builder/manifest', __dir__)
    autoload :Processors, File.expand_path('builder/processors', __dir__)
    autoload :Rainbow, File.expand_path('builder/rainbow', __dir__)
    autoload :Plugin, File.expand_path('builder/plugin', __dir__)
    autoload :PluginCollection, File.expand_path('builder/plugin_collection', __dir__)
    autoload :StepCollection, File.expand_path('builder/step_collection', __dir__)
    autoload :TemplateManager, File.expand_path('builder/template_manager', __dir__)
    autoload :PluginManager, File.expand_path('builder/plugin_manager', __dir__)

    BUILDKITE_DIRECTORY_NAME = Pathname.new('.buildkite').freeze
    META_DATA = {
      job: 'buildkite-builder.job'
    }.freeze

    class << self
      def root(start_path: Dir.pwd, reset: false)
        @root = nil if reset
        @root ||= find_buildkite_directory(start_path)
      end

      def template(&block)
        Definition::Template.new(&block) if block_given?
      end

      def pipeline(&block)
        Definition::Pipeline.new(&block) if block_given?
      end

      private

      def find_buildkite_directory(start_path)
        path = Pathname.new(start_path)
        until path.join(BUILDKITE_DIRECTORY_NAME).directory?
          raise "Unable to find #{BUILDKITE_DIRECTORY_NAME} from #{start_path}" if path == path.parent

          path = path.parent
        end
        path.expand_path
      end

    end
  end
end
