# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Run < Abstract
        private

        self.description = 'Builds and uploads the generated pipeline.'

        def run
          Builder::Runner.run
        end
      end
    end
  end
end
