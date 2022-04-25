# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # String represents a ruby string value.
  class String
    include Comparable

    # Initialize a String.
    # @param value [String] the string value
    def initialize(value:)
      @value = value
    end

    # Get valid operators.
    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    # Get the actual value of a node.
    # @param node [Parser::AST::Node] the node
    # @return [String] if node is a Parser::AST::Node, return the node source code, otherwise, return the string value.
    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      else
        node.to_s
      end
    end

    def to_s
      "\"#{@value}\""
    end
  end
end
