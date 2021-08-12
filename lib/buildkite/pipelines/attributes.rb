# frozen_string_literal: true

require 'set'

module Buildkite
  module Pipelines
    module Attributes
      def self.included(base)
        base.extend(ClassMethods)
      end

      def get(attr)
        attributes[validate(attr)]
      end

      def set(attr, value)
        attributes[validate(attr)] = value
      end

      def has?(attr)
        # Don't validate for has? calls.
        attributes.key?(attr.to_s)
      end

      def permits?(attr)
        self.class.permits?(attr)
      end

      def append(attr, value)
        ensure_array_value(attr)
        get(attr).push(*[value].flatten)
        value
      end

      def prepend(attr, value)
        ensure_array_value(attr)
        get(attr).unshift(*[value].flatten)
        value
      end

      def permitted_attributes
        self.class.permitted_attributes
      end

      def unset(attr)
        attributes.delete(validate(attr))
      end

      def to_pipeline
        permitted_attributes.each_with_object({}) do |attr, hash|
          hash[attr] = get(attr) if has?(attr)
        end
      end

      module ClassMethods
        def inherited(subclass)
          subclass.permitted_attributes.merge(permitted_attributes)
        end

        def permitted_attributes
          @permitted_attributes ||= Set.new
        end

        def permits?(attr)
          @permitted_attributes.include?(attr.to_s)
        end

        def attribute(attribute_name, **options)
          unless permitted_attributes.add?(attribute_name.to_s)
            raise "Step already defined attribute: #{attribute_name}"
          end

          method_name = options.fetch(:as, attribute_name)

          # Define the main helper method that sets or appends the attribute value.
          define_method(method_name) do |*value|
            if value.empty?
              get(attribute_name)
            elsif options[:append]
              append(attribute_name, *value)
            else
              set(attribute_name, *value)
            end
          end

          # Define a helper method that is equivalent to `||=` or `Set#add?`. It will
          # set the attribute if it hasn't been already set. It will return true/false
          # for whether or not the value was set.
          define_method("#{method_name}?") do |*args|
            if args.empty?
              raise ArgumentError, "`#{method_name}?` must be called with arguments"
            elsif has?(method_name)
              false
            else
              public_send(method_name, *args)
              true
            end
          end

          if options[:append]
            # If this attribute appends by default, then provide a bang(!) helper method
            # that allows you to clear and set the value in one go.
            define_method("#{method_name}!") do |*args|
              unset(attribute_name)
              public_send(method_name, *args)
            end
          end

          Helpers.prepend_attribute_helper(self, attribute_name)
        end
      end

      private

      def attributes
        @attributes ||= {}
      end

      def ensure_array_value(attr)
        if has?(attr)
          set(attr, [get(attr)]) unless get(attr).is_a?(Array)
        else
          set(attr, [])
        end
      end

      def validate(attr)
        attr = attr.to_s
        unless permits?(attr)
          raise "Attribute not permitted on #{self.class.name} step: #{attr}"
        end

        attr
      end
    end
  end
end
