module Buildkite
  module Builder
    module Extensions
      class Steps < Extension
        dsl do
          def group(label = nil, &block)
            data[:steps].push(Buildkite::Builder::Group.new(label, &block))
          end
        end
      end
    end
  end
end
