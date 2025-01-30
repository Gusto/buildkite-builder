module Extensions
  class PipelineSpecificExtension < Buildkite::Builder::Extension
    def build
      pipeline do
        command do
          label 'Appended By Extensions::PipelineSpecificExtension'
          command 'echo 1'
        end
      end
    end
  end
end
