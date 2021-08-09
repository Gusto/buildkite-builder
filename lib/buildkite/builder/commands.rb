# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      using Rainbow
      COMMANDS = {
        'files' => :Files,
        'preview' => :Preview,
        'run' => :Run
      }.freeze

      autoload :Abstract, File.expand_path('commands/abstract', __dir__)
      COMMANDS.each do |command, klass|
        autoload klass, File.expand_path("commands/#{command}", __dir__)
      end

      def self.run
        if ARGV.empty? || ARGV.first == '--help'
          return print_help
        end

        command = ARGV.shift
        unless (command_class = COMMANDS[command])
          raise "Invalid command: #{command}"
        end

        const_get(command_class).execute
      end

      def self.print_help
        puts <<~HELP
          #{'SYNOPSIS'.bright}
          \t#{'buildkite-builder'.bright} COMMAND [OPTIONS] [PIPELINE]

          \t#{'To see available options for specific commands:'.color(:dimgray)}
          \t#{'buildkite-builder'.bright} COMMAND --help

          #{'COMMANDS'.bright}
        HELP
        COMMANDS.each do |command, klass|
          puts <<~HELP
            \t#{command.bright}
            \t#{const_get(klass).description.color(:dimgray)}\n
          HELP
        end
      end
    end
  end
end
