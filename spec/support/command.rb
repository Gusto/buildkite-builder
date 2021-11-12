# frozen_string_literal: true

module Spec
  module Support
    module Command
      class << self
        attr_reader :stubbed

        def stub!
          @stubbed = true
        end

        def unstub!
          @stubbed = false
        end
      end

      def run
        return true if Spec::Support::Command.stubbed

        super
      end
    end
  end
end

Spec::Support::Command.stub!
Buildkite::Pipelines::Command.prepend(Spec::Support::Command)
