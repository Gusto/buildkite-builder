# frozen_string_literal: true

require 'open3'
require 'set'

module Buildkite
  module Builder
    class FileResolver
      @cache = true

      attr_reader :modified_files

      class << self
        attr_accessor :cache

        def resolve(reset = false)
          @resolve = nil if !cache || reset
          @resolve ||= new
        end
      end

      def initialize
        @modified_files = Set.new(pull_request? ? files_from_pull_request.sort! : files_from_git.sort!)
      end

      private

      def files_from_pull_request
        Github.pull_request_files.map { |f| f.fetch('filename') }
      end

      def files_from_git
        if Buildkite.env
          changed_files = command("git diff-tree --no-commit-id --name-only -r #{Buildkite.env.commit}")
        else
          default_branch = command('git symbolic-ref refs/remotes/origin/HEAD').strip
          changed_files = command("git diff --name-only #{default_branch}")
          changed_files << command('git diff --name-only')
        end

        changed_files.split.uniq.sort
      end

      def pull_request?
        Buildkite.env&.pull_request
      end

      def command(cmd)
        output, status = Open3.capture2(*cmd.split)

        if status.success?
          output
        else
          raise "Command failed (exit #{status.exitstatus}): #{cmd}"
        end
      end
    end
  end
end
