module Extensions
  class SharedExtension < Buildkite::Builder::Extension
    def build
      pipeline do
        command do
          label 'Appended By Extensions::SharedExtension'
          command 'echo 1'
        end
      end
    end
  end
end
