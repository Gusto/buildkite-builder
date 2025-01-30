module Extensions
  class Basic < Buildkite::Builder::Extension
    def build
      pipeline.command do
        label 'Appended Step'
        command 'echo 1'
      end
    end
  end
end
