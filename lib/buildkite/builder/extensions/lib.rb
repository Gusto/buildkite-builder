module Buildkite
  module Builder
    module Extensions
      class Lib < Extension
        def prepare
          lib_dir = Buildkite::Builder::BUILDKITE_DIRECTORY_NAME.join('lib')
          $LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
        end
      end
    end
  end
end
