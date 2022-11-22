module Buildkite
  module Builder
    class ExtensionManager
      include LoggingUtils
      using Rainbow

      def initialize(context)
        @context = context
        @extensions = {}

        @loader = Loaders::Extensions.load(@context.root)
      end

      def use(extension, native: false, **args, &block)
        unless extension < Buildkite::Builder::Extension
          raise "#{extension.name} must subclass Buildkite::Builder::Extension"
        end

        if @extensions[extension]
          raise "#{extension.name} already registered"
        end

        @extensions[extension] = extension.new(@context, **args, &block)
        @context.dsl.extend(extension)
      end

      def build
        @extensions.each do |extension_class, extension|
          log_build(extension_class.name) { extension.build }
        end
      end

      def find(klass)
        @extensions.fetch(klass)
      end

      private

      def log
        @context.logger
      end

      def log_build(name)
        log.info "\nProcessing ".color(:dimgray) + name.color(:springgreen)

        results = benchmark('└──'.color(:springgreen) + ' Finished in %s'.color(:dimgray)) do
          formatter = log.formatter
          log.formatter = proc do |_severity, _datetime, _progname, msg|
            '│'.color(:springgreen) + " #{msg}\n"
          end

          begin
            yield
          ensure
            log.formatter = formatter
          end
        end

        log.info results
      end
    end
  end
end
