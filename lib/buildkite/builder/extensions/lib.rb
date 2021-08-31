module Buildkite
  module Builder
    module Extensions
      class Lib < Extension
        def prepare
          lib_dir = Buildkite::Builder.root.join(Buildkite::Builder::BUILDKITE_DIRECTORY_NAME, 'lib')

          if lib_dir.directory? && !$LOAD_PATH.include?(lib_dir)
            $LOAD_PATH.unshift(lib_dir)
          end
        end
      end
    end
  end
end
