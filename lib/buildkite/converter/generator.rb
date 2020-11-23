module Buildkite
  module Converter
    class Generator
      attr_reader :pipeline, :target, :name

      def initialize(name, pipeline_yml, target_project)
        pipeline_yml = Pathname.new(pipeline_yml).expand_path.to_s
        target_project = Pathname.new(target_project).expand_path

        @name = name # Remember to only accept dashify-names
        @pipeline = PipelineYml.new(pipeline_yml)
        @target = target_project

        @pipeline.parsed_steps
      end

      def build
        @pipeline_folder = target.join(".buildkite/pipelines/#{name}")
        @pipeline_folder.mkdir unless @pipeline_folder.exist?

        @templates_folder = @pipeline_folder.join('templates')
        @templates_folder.mkdir unless @templates_folder.exist?

        contents = []

        pipeline.parsed_steps.each_with_index do |step, idx|
          if step.type == :Wait
            contents << step.contents
          else
            reference = create_template(step, idx)
            output = "#{step.type.downcase}(:#{reference})"

            contents << output
          end
        end

        create_pipeline_rb(contents)
      end

      def create_pipeline_rb(contents)
        body = contents.flatten.map do |string|
          unless string.is_a?(String)
            binding.pry
            raise "Expecting a String, but got a #{string.class} instead."
          end

          bits = string.split("\n")
          bits.map { |bit| "  #{bit}"}.join("\n")
        end

        plugins_content = PluginsStore.contents.map do |string|
          "  #{string}"
        end

        body.prepend(*plugins_content)

        file_header = 'Buildkite::Builder.pipeline do'
        file_end = 'end'

        body.prepend(file_header)
        body.append(file_end)

        file_path = @pipeline_folder.join('pipeline.rb')

        puts "\nFile: #{file_path}"
        puts "Contents:\n#{body.join("\n")}\n"

        # File.open(file_path, 'wb') do |file|
        #   file.puts body.join("\n")
        # end
      end

      def create_template(step, number)
        body = step.contents.map do |string|
          unless string.is_a?(String)
            binding.pry
            raise "Expecting a String, but got a #{string.class} instead."
          end

          bits = string.split("\n")
          bits.map { |bit| "  #{bit}"}.join("\n")
        end

        file_header = 'Buildkite::Builder.template do'
        file_end = 'end'

        body.prepend(file_header)
        body.append(file_end)

        template_identifier = "#{step.type.downcase}_#{number}"

        file_path = @templates_folder.join("#{template_identifier}.rb")

        puts "\nFile: #{file_path}"
        puts "Contents:\n#{body.join("\n")}\n"

        # File.open(file_path, 'wb') do |file|
        #   file.puts body.join("\n")
        # end

        template_identifier
      end


    end
  end
end
