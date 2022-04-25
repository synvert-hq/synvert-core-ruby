# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Regexp represents a ruby regexp value.
  class Regexp
    include Comparable

    # Initialize a Regexp.
    # @param value [Regexp] the regexp value
    def initialize(value:)
      @value = value
    end

    # Check if the regexp value matches the node value.
    # @param node [Parser::AST::Node] the node
    # @param operator [Symbol] the operator
    # @return [Boolean] true if the regexp value matches the node value, otherwise, false.
    def match?(node, operator = :=~)
      match =
        if node.is_a?(::Parser::AST::Node)
          @value.match(node.to_source)
        else
          @value.match(node.to_s)
        end
      operator == :=~ ? match : !match
    end

    # Get valid operators.
    def valid_operators
      REGEXP_VALID_OPERATORS
    end

    def to_s
      @value.to_s
    end
  end
end