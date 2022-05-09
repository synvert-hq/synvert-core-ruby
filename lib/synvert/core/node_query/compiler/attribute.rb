# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Attribute is a pair of key, value and operator,
  class Attribute
    # Initialize a Attribute.
    # @param key [String] the key
    # @param value the value can be any class implement {Synvert::Core::NodeQuery::Compiler::Comparable}
    # @param operator [Symbol] the operator
    def initialize(key:, value:, operator: '==')
      @key = key
      @value = value
      @operator = operator
    end

    # Check if the node matches the attribute.
    # @param node [Parser::AST::Node] the node
    # @return [Boolean]
    def match?(node)
      @value.base_node = node if @value.is_a?(DynamicAttribute)
      node && @value.match?(node.child_node_by_name(@key), @operator)
    end

    def to_s
      case @operator
      when '*=', '!=', '=~', '!~', '>=', '>', '<=', '<'
        "#{@key}#{@operator}#{@value}"
      when 'in'
        "#{@key} in (#{@value})"
      when 'not_in'
        "#{@key} not in (#{@value})"
      when 'includes'
        "#{@key} includes #{@value}"
      else
        "#{@key}=#{@value}"
      end
    end
  end
end
