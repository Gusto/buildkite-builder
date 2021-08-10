module Processors
  class PipelineSpecificProcessor < Buildkite::Builder::Processors::Abstract
    private

    def process(foo:)
      pipeline.command do
        label 'Appended By Processors::PipelineSpecificProcessor'
        command 'echo 1'
      end
    end
  end
end
