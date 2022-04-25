# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Selector used to match nodes, it combines by node type and/or attribute list, plus index or has expression.
  class Selector
    # Initialize a Selector.
    # @param node_type [String] the node type
    # @param attribute_list [Synvert::Core::NodeQuery::Compiler::AttributeList] the attribute list
    # @param index [Integer] the index
    # @param has_expression [Synvert::Core::NodeQuery::Compiler::Expression] the has expression
    def initialize(node_type: nil, attribute_list: nil, index: nil, has_expression: nil)
      @node_type = node_type
      @attribute_list = attribute_list
      @index = index
      @has_expression = has_expression
    end

    # Filter nodes by index.
    def filter(nodes)
      return nodes if @index.nil?

      nodes[@index] ? [nodes[@index]] : []
    end

    # Check if node matches the selector.
    # @param node [Parser::AST::Node] the node
    def match?(node, _operator = :==)
      (!@node_type || (node.is_a?(::Parser::AST::Node) && @node_type.to_sym == node.type)) &&
      (!@attribute_list || @attribute_list.match?(node)) &&
      (!@has_expression || @has_expression.match?(node))
    end

    def to_s
      str = ".#{@node_type}#{@attribute_list}"
      return str if !@index && !@has_expression

      return "#{str}:has(#{@has_expression.to_s})" if @has_expression

      case @index
      when 0
        str + ':first-child'
      when -1
        str + ':last-child'
      when (1..)
        str + ":nth-child(#{@index + 1})"
      when (...-1)
        str + ":nth-last-child(#{-@index})"
      else
        str
      end
    end
  end
end