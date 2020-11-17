module Processors
  class SharedProcessor < Buildkite::Builder::Processors::Abstract
    private

    def process
      pipeline.command do
        label 'Appended By Processors::SharedProcessor'
        command 'echo 1'
      end
    end
  end
end
