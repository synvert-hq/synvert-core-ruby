# frozen_string_literal: true

module Synvert::Core::NodeQuery
  class Compiler
    class InvalidOperator < StandardError; end

    module Comparable
      SIMPLE_VALID_OPERATORS = [:==, :!=]
      NUMBER_VALID_OPERATORS = [:==, :!=, :>, :>=, :<, :<=]
      REGEXP_OPERATORS = [:=~, :!~]

      def match?(node, operator)
        raise InvalidOperator, "invalid operator #{operator}" unless valid_operator?(operator)

        case operator
        when :!=
          actual_value(node) != expected_value
        when :=~
          actual_value(node) =~ expected_value
        when :!~
          actual_value(node) !~ expected_value
        when :>
          actual_value(node) > expected_value
        when :>=
          actual_value(node) >= expected_value
        when :<
          actual_value(node) < expected_value
        when :<=
          actual_value(node) <= expected_value
        else
          actual_value(node) == expected_value
        end
      end

      def actual_value(node)
        node.to_value
      end

      def expected_value
        @value
      end

      def valid_operator?(operator)
        valid_operators.include?(operator)
      end
    end

    class Expression
      def initialize(selector:, another_selector: nil, relationship: nil)
        @selector = selector
        @another_selector = another_selector
        @relationship = relationship
      end

      def query_nodes(node)
        case @relationship
        when :descendant
          find_nodes_with_descendant_relationship(node, match?(node))
        when :child
          find_nodes_with_child_relationship(node, match?(node))
        when :next_sibling
          find_nodes_with_next_sibling_relationship(node)
        when :sebsequent_sibling
          find_nodes_with_subsequent_sibling_relationship(node)
        else
          find_nodes_with_nil_relationship(node)
        end
      end

      def match?(node)
        @selector.match?(node)
      end

      def another_match?(node)
        @another_selector.match?(node)
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

      private

      def find_nodes_with_descendant_relationship(node, ancestor_match = false)
        nodes = []
        if ancestor_match
          node.recursive_children do |child_node|
            if another_match?(child_node)
              nodes << child_node
            end
          end
        else
          node.recursive_children do |child_node|
            if match?(child_node)
              nodes += find_nodes_with_descendant_relationship(child_node, true)
            end
          end
        end
        nodes
      end

      def find_nodes_with_child_relationship(node, parent_match = false)
        nodes = []
        if parent_match
          node.children.each do |child_node|
            if child_node.is_a?(::Parser::AST::Node)
              match = another_match?(child_node)
              nodes << child_node if match
              nodes += find_nodes_with_child_relationship(child_node, match)
            end
          end
        else
          node.children.each do |child_node|
            if child_node.is_a?(::Parser::AST::Node)
              nodes += find_nodes_with_child_relationship(child_node, match?(child_node))
            end
          end
        end
        nodes
      end

      def find_nodes_with_next_sibling_relationship(node)
        nodes = []
        first_match = false
        node.children.each do |child_node|
          if !first_match && match?(child_node)
            first_match = true
          elsif first_match && another_match?(child_node)
            first_match = false
            nodes << child_node
          else
            first_match = false
          end
          if child_node.is_a?(::Parser::AST::Node)
            nodes += find_nodes_with_next_sibling_relationship(child_node)
          end
        end
        nodes
      end

      def find_nodes_with_subsequent_sibling_relationship(node)
        nodes = []
        first_match = false
        node.children.each do |child_node|
          if !first_match && match?(child_node)
            first_match = true
          elsif first_match && another_match?(child_node)
            nodes << child_node
          end
          if child_node.is_a?(::Parser::AST::Node)
            nodes += find_nodes_with_subsequent_sibling_relationship(child_node)
          end
        end
        nodes
      end

      def find_nodes_with_nil_relationship(node)
        nodes = []
        nodes << node if match?(node)
        node.recursive_children do |child_node|
          nodes << child_node if match?(child_node)
        end
        nodes
      end
    end

    class Selector
      def initialize(node_type: nil, attribute_list: nil)
        @node_type = node_type
        @attribute_list = attribute_list
      end

      def match?(node, operator = :==)
        (!@node_type || (node.is_a?(::Parser::AST::Node) && @node_type.to_sym == node.type)) &&
          (!@attribute_list || @attribute_list.match?(node, operator))
      end

      def to_s
        ".#{@node_type}#{@attribute_list}"
      end
    end

    class AttributeList
      def initialize(attribute:, attribute_list: nil)
        @attribute = attribute
        @attribute_list = attribute_list
      end

      def match?(node, operator = :==)
        @attribute.match?(node, operator) && (!@attribute_list || @attribute_list.match?(node, operator))
      end

      def to_s
        "[#{@attribute}]#{@attribute_list}"
      end
    end

    class Attribute
      def initialize(key:, value:, operator: :==)
        @key = key
        @value = value
        @operator = operator
      end

      def match?(node, operator = :==)
        @value.base_node = node if @value.is_a?(AttributeValue)
        node && @value.match?(node.child_node_by_name(@key), @operator)
      end

      def to_s
        case @operator
        when :!=
          "#{@key}!=#{@value}"
        when :=~
          "#{@key}=~#{@value}"
        when :!~
          "#{@key}!~#{@value}"
        when :>
          "#{@key}>#{@value}"
        when :>=
          "#{@key}>=#{@value}"
        when :<
          "#{@key}<#{@value}"
        when :<=
          "#{@key}<=#{@value}"
        else
          "#{@key}=#{@value}"
        end
      end
    end

    class AttributeValue
      include Comparable

      attr_accessor :base_node

      def initialize(value:)
        @value = value
      end

      def actual_value(node)
        node.to_source
      end

      def expected_value
        base_node.child_node_by_name(@value).to_source
      end

      def valid_operators
        SIMPLE_VALID_OPERATORS
      end

      def to_s
        "{{#{@value}}}"
      end
    end

    class Boolean
      include Comparable

      def initialize(value:)
        @value = value
      end

      def to_s
        @value.to_s
      end

      def valid_operators
        SIMPLE_VALID_OPERATORS
      end
    end

    class Float
      include Comparable

      def initialize(value:)
        @value = value
      end

      def actual_value(node)
        if node.is_a?(::Parser::AST::Node)
          node.to_value
        else
          node.to_f
        end
      end

      def valid_operators
        NUMBER_VALID_OPERATORS
      end

      def to_s
        @value.to_s
      end
    end

    class Integer
      include Comparable

      def initialize(value:)
        @value = value
      end

      def actual_value(node)
        if node.is_a?(::Parser::AST::Node)
          node.to_value
        else
          node.to_i
        end
      end

      def valid_operators
        NUMBER_VALID_OPERATORS
      end

      def to_s
        @value.to_s
      end
    end

    class Nil
      include Comparable

      def initialize(value:)
        @value = value
      end

      def actual_value(node)
        node
      end

      def valid_operators
        SIMPLE_VALID_OPERATORS
      end

      def to_s
        'nil'
      end
    end

    class Regexp
      include Comparable

      def initialize(value:)
        @value = value
      end

      def match?(node, operator)
        if node.is_a?(::Parser::AST::Node)
          @value.match(node.to_source)
        else
          @value.match(node.to_s)
        end
      end

      def valid_operators
        REGEXP_OPERATORS
      end

      def to_s
        @value.to_s
      end
    end

    class String
      include Comparable

      def initialize(value:)
        @value = value
      end

      def valid_operators
        SIMPLE_VALID_OPERATORS
      end

      def to_s
        "\"#{@value}\""
      end
    end

    # Symbol node represents a symbol value.
    class Symbol
      include Comparable

      def initialize(value:)
        @value = value
      end

      def actual_value(node)
        if node.is_a?(::Parser::AST::Node)
          node.to_value
        else
          node
        end
      end

      def valid_operators
        SIMPLE_VALID_OPERATORS
      end

      def to_s
        ":#{@value}"
      end
    end

    class Identifier
      include Comparable

      def initialize(value:)
        @value = value
      end

      def actual_value(node)
        if node.is_a?(::Parser::AST::Node)
          node.type == :const && node.children.last.to_s
        else
          node.to_s
        end
      end

      def valid_operators
        SIMPLE_VALID_OPERATORS
      end

      def to_s
        @value
      end
    end
  end
end
