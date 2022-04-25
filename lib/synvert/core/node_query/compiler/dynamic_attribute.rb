# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # DynamicAttribute represents a ruby dynamic attribute.
  # e.g. code is <code>{ a: a }</code>, query is <code>'.hash > .pair[key={{value}}]'</code>,
  # <code>{{value}}</code> is the dynamic attribute.
  class DynamicAttribute
    include Comparable

    attr_accessor :base_node

    # Initialize a DynamicAttribute.
    # @param value [String] the dynamic attribute value
    def initialize(value:)
      @value = value
    end

    # Get the actual value of a node.
    #
    # @param node the node
    # @return [String] if node is a {Parser::AST::Node}, return the node source code, otherwise return the node itself.
    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      else
        node
      end
    end

    # Get the expected value.
    #
    # @return [String] Query the node by @valud from base_node, if the node is a {Parser::AST::Node}, return the node source code, otherwise return the node itself.
    def expected_value
      node = base_node.child_node_by_name(@value)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      else
        node
      end
    end

    # Get valid operators.
    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      "{{#{@value}}}"
    end
  end
end
