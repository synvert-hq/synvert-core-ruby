# frozen_string_literal: true

module Synvert::Core::NodeQuery
  class Compiler
    class Expression
      def initialize(selector, another_selector = nil, relationship: nil)
        @selector = selector
        @another_selector = another_selector
        @relationship = relationship
      end

      def find_nodes(node)
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
      def initialize(node_type, attribute_list = nil)
        @node_type = node_type
        @attribute_list = attribute_list
      end

      def match?(node)
        node.is_a?(::Parser::AST::Node) && @node_type.to_sym == node.type && (!@attribute_list || @attribute_list.match?(node))
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

      def match?(node)
        @attribute.match?(node) && (!@attribute_list || @attribute_list.match?(node))
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

      def match?(node)
        @value.match?(node.send(@key))
      end

      def to_s
        "#{@key}=#{@value}"
      end
    end

    class Boolean
      def initialize(value)
        @value = value
      end

      def match?(node)
        @value == node.to_value
      end

      def to_s
        @value.to_s
      end
    end

    class Float
      def initialize(value)
        @value = value
      end

      def match?(node)
        @value == node.to_value
      end

      def to_s
        @value.to_s
      end
    end

    class Integer
      def initialize(value)
        @value = value
      end

      def match?(node)
        @value == node.to_value
      end

      def to_s
        @value.to_s
      end
    end

    class Nil
      def initialize(value)
        @value = value
      end

      def match?(node)
        @value == node.to_value
      end

      def to_s
        'nil'
      end
    end

    class Regexp
      def initialize(value)
        @value = value
      end

      def match?(node)
        if node.is_a?(::Parser::AST::Node)
          @value.match(node.to_source)
        else
          @value.match(node.to_s)
        end
      end

      def to_s
        @value.to_s
      end
    end

    class String
      def initialize(value)
        @value = value
      end

      def match?(node)
        @value == node.to_value
      end

      def to_s
        "\"#{@value}\""
      end
    end

    # Symbol node represents a symbol value.
    class Symbol
      def initialize(value)
        @value = value
      end

      def match?(node)
        if node.is_a?(::Parser::AST::Node)
          @value == node.to_value
        else
          @value == node
        end
      end

      def to_s
        ":#{@value}"
      end
    end

    class Identifier
      def initialize(value)
        @value = value
      end

      def match?(node)
        if node.is_a?(::Parser::AST::Node)
          node.type == :const && node.children.last.to_s == @value
        else
          node.to_s == @value
        end
      end

      def to_s
        @value
      end
    end
  end
end