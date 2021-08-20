module Extensions
  class Feature < Buildkite::Builder::Extension
    def build
      pipeline do
        command do
          label 'Appended Step'
          command 'echo 1'
        end
      end
    end
  end
end
