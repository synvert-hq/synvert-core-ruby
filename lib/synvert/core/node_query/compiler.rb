# frozen_string_literal: true

module Synvert::Core::NodeQuery
  class Compiler
    class Expression
      def initialize(selector, another_selector = nil, relationship: nil)
        @selector = selector
        @another_selector = another_selector
        @relationship = relationship
      end

      def to_s
        return @selector.to_s unless @another_selector

        result = [@selector]
        case @relationship
        when :child then result << '>'
        when :sebsequent_sibling then result << '~'
        when :next_sibling then result << '+'
        end
        result << @another_selector
        result.map(&:to_s).join(' ')
      end
    end

    class Selector
      def initialize(node_type, attribute_list = nil)
        @node_type = node_type
        @attribute_list = attribute_list
      end

      def to_s
        ".#{@node_type}#{@attribute_list}"
      end
    end

    class AttributeList
      def initialize(attribute, attribute_list = nil)
        @attribute = attribute
        @attribute_list = attribute_list
      end

      def to_s
        "[#{@attribute}]#{@attribute_list}"
      end
    end

    class Attribute
      def initialize(key, value, operation: :equal)
        @key = key
        @value = value
        @operation = operation
      end

      def to_s
        "#{@key}=#{@value}"
      end
    end

    class Boolean
      def initialize(value)
        @value = value
      end

      def to_s
        @value.to_s
      end
    end

    class Float
      def initialize(value)
        @value = value
      end

      def to_s
        @value.to_s
      end
    end

    class Integer
      def initialize(value)
        @value = value
      end

      def to_s
        @value.to_s
      end
    end

    class Nil
      def initialize(value)
        @value = value
      end

      def to_s
        'nil'
      end
    end

    class Regexp
      def initialize(value)
        @value = value
      end

      def to_s
        @value.to_s
      end
    end

    class String
      def initialize(value)
        @value = value
      end

      def to_s
        "\"#{@value}\""
      end
    end

    class Symbol
      def initialize(value)
        @value = value
      end

      def to_s
        ":#{@value}"
      end
    end
  end
end