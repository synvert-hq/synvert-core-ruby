# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Identifier represents a ruby identifier value.
  # e.g. code is `class Synvert; end`, `Synvert` is an identifier.
  class Identifier
    include Comparable

    # Initialize an Identifier.
    # @param value [String] the identifier value
    def initialize(value:)
      @value = value
    end

    # Get the actual value.
    #
    # @param node the node
    # @return [String|Array]
    # If the node is a {Parser::AST::Node}, return the node source code,
    # if the node is an Array, return the array of each element's actual value,
    # otherwise, return the String value.
    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      elsif node.is_a?(::Array)
        node.map { |n| actual_value(n) }
      else
        node.to_s
      end
    end

    # Get valid operators.
    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      @value
    end
  end
end
