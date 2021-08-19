module Extensions
  class Basic < Buildkite::Builder::Extension
    private

    def process
      pipeline.command do
        label 'Appended Step'
        command 'echo 1'
      end
    end
  end
end
