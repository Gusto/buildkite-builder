# frozen_string_literal: true

module Buildkite
  class Env
    BUILDKITE = 'BUILDKITE'
    PREFIX = "#{BUILDKITE}_"

    module Fallback
      def method_missing(method_name, *_args, &_block) # rubocop:disable Style/MethodMissingSuper
        env_name = "#{PREFIX}#{method_name.to_s.gsub(/\?\z/, '').upcase}"

        if method_name.to_s.end_with?('?')
          @env.key?(env_name)
        elsif @env.key?(env_name)
          @env.fetch(env_name)
        else
          raise NoMethodError, "undefined method #{method_name} for #{self} because ENV[\"#{env_name}\"] is not defined"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.end_with?('?') || @env.key?("#{PREFIX}#{method_name.upcase}") || super
      end
    end
    include Fallback

    def self.load(env)
      new(env) if env[BUILDKITE]
    end

    def initialize(env)
      @env = env
    end

    def default_branch?
      pipeline_default_branch == branch
    end

    def pull_request
      super == 'false' ? false : Integer(super)
    end

    # Integer methods
    %w(
      build_number
    ).each do |meth|
      define_method(meth) do
        Integer(super())
      end
    end
  end
end
