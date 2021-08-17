module Extensions
  class PipelineSpecificExtension < Buildkite::Builder::Extension
    private

    def process(foo:)
      pipeline.command do
        label 'Appended By Extensions::PipelineSpecificExtension'
        command 'echo 1'
      end
    end
  end
end
