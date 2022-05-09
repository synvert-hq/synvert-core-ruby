# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Compare acutal value with expected value.
  module Comparable
    SIMPLE_VALID_OPERATORS = ['==', '!=', 'includes']
    STRING_VALID_OPERATORS = ['==', '!=', '*=', 'includes']
    NUMBER_VALID_OPERATORS = ['==', '!=', '>', '>=', '<', '<=', 'includes']
    ARRAY_VALID_OPERATORS = ['==', '!=', 'in', 'not_in']
    REGEXP_VALID_OPERATORS = ['=~', '!~']

    # Check if the actual value matches the expected value.
    #
    # @param node [Parser::AST::Node] node to calculate actual value
    # @param operator [Symbol] operator to compare with expected value, operator can be <code>'=='</code>, <code>'!='</code>, <code>'>'</code>, <code>'>='</code>, <code>'<'</code>, <code>'<='</code>, <code>'includes'</code>, <code>'in'</code>, <code>'not_in'</code>, <code>'=~'</code>, <code>'!~'</code>
    # @return [Boolean] true if actual value matches the expected value
    # @raise [Synvert::Core::NodeQuery::Compiler::InvalidOperatorError] if operator is invalid
    def match?(node, operator)
      raise InvalidOperatorError, "invalid operator #{operator}" unless valid_operator?(operator)

      case operator
      when '!='
        if expected_value.is_a?(::Array)
          actual = actual_value(node)
          !actual.is_a?(::Array) || actual.size != expected_value.size ||
            actual.zip(expected_value).any? { |actual_node, expected_node| expected_node.match?(actual_node, '!=') }
        else
          actual_value(node) != expected_value
        end
      when '=~'
        actual_value(node) =~ expected_value
      when '!~'
        actual_value(node) !~ expected_value
      when '*='
        actual_value(node).include?(expected_value)
      when '>'
        actual_value(node) > expected_value
      when '>='
        actual_value(node) >= expected_value
      when '<'
        actual_value(node) < expected_value
      when '<='
        actual_value(node) <= expected_value
      when 'in'
        expected_value.any? { |expected| expected.match?(node, '==') }
      when 'not_in'
        expected_value.all? { |expected| expected.match?(node, '!=') }
      when 'includes'
        actual_value(node).any? { |actual| actual == expected_value }
      else
        if expected_value.is_a?(::Array)
          actual = actual_value(node)
          actual.is_a?(::Array) && actual.size == expected_value.size &&
            actual.zip(expected_value).all? { |actual_node, expected_node| expected_node.match?(actual_node, '==') }
        else
          actual_value(node) == expected_value
        end
      end
    end

    # Get the actual value from ast node.
    # @return if node is a {Parser::AST::Node}, return the node value, otherwise, return the node itself.
    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_value
      else
        node
      end
    end

    # Get the expected value
    def expected_value
      @value
    end

    # Check if the operator is valid.
    # @return [Boolean] true if the operator is valid
    def valid_operator?(operator)
      valid_operators.include?(operator)
    end
  end
end
