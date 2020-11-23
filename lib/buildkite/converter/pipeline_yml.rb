module Buildkite
  module Converter
    class PipelineYml
      attr_reader :parsed_yml, :file

      def initialize(file)
        @file = file
        load_and_parse_yml
      end

      def steps
        @steps ||= @parsed_yml.fetch('steps', [])
      end

      def parsed_steps
        @parsed_steps ||= steps.map do |step|
          step_obj = PipelineStep.new(step)
          step_obj.parse

          step_obj
        end
      end

      private

      def load_and_parse_yml
        @parsed_yml = Psych.load_file(@file)
      end
    end
  end
end