# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Selector used to match nodes, it combines by node type and/or attribute list, plus index or has expression.
  class Selector
    # Initialize a Selector.
    # @param node_type [String] the node type
    # @param attribute_list [Synvert::Core::NodeQuery::Compiler::AttributeList] the attribute list
    # @param index [Integer] the index
    # @param pseudo_class [String] the pseudo class, can be <code>has</code> or <code>not_has</code>
    # @param pseudo_expression [Synvert::Core::NodeQuery::Compiler::Expression] the pseudo expression
    def initialize(node_type:, attribute_list: nil, index: nil, pseudo_class: nil, pseudo_expression: nil)
      @node_type = node_type
      @attribute_list = attribute_list
      @index = index
      @pseudo_class = pseudo_class
      @pseudo_expression = pseudo_expression
    end

    # Filter nodes by index.
    def filter(nodes)
      return nodes if @index.nil?

      nodes[@index] ? [nodes[@index]] : []
    end

    # Check if node matches the selector.
    # @param node [Parser::AST::Node] the node
    def match?(node, _operator = '==')
      node.is_a?(::Parser::AST::Node) && @node_type.to_sym == node.type &&
        (!@attribute_list || @attribute_list.match?(node)) &&
        (!@pseudo_class || (@pseudo_class == 'has' && @pseudo_expression.match?(node)) || (@pseudo_class == 'not_has' && !@pseudo_expression.match?(node)))
    end

    def to_s
      result = [".#{@node_type}"]
      result << @attribute_list.to_s if @attribute_list
      result << ":#{@pseudo_class}(#{@pseudo_expression})" if @pseudo_class
      if @index
        result <<
          case @index
          when 0
            ':first-child'
          when -1
            ':last-child'
          when (1..)
            ":nth-child(#{@index + 1})"
          else # ...-1
            ":nth-last-child(#{-@index})"
          end
      end
      result.join('')
    end
  end
end
