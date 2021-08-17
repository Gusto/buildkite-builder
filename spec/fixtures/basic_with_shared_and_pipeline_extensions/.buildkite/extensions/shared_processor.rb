module Extensions
  class SharedExtension < Buildkite::Builder::Extension
    private

    def process
      pipeline.command do
        label 'Appended By Extensions::SharedExtension'
        command 'echo 1'
      end
    end
  end
end
