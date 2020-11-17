module Processors
  class Basic < Buildkite::Builder::Processors::Abstract
    private

    def process
      pipeline.command do
        label 'Appended Step'
        command 'echo 1'
      end
    end
  end
end
