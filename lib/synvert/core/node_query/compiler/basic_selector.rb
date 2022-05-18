# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # BasicSelector used to match nodes, it combines by node type and/or attribute list.
  class BasicSelector
    # Initialize a BasicSelector.
    # @param node_type [String] the node type
    # @param attribute_list [Synvert::Core::NodeQuery::Compiler::AttributeList] the attribute list
    def initialize(node_type:, attribute_list: nil)
      @node_type = node_type
      @attribute_list = attribute_list
    end

    # Check if node matches the selector.
    # @param node [Parser::AST::Node] the node
    def match?(node, _operator = '==')
      return false unless node

      @node_type.to_sym == node.type && (!@attribute_list || @attribute_list.match?(node))
    end

    def to_s
      result = [".#{@node_type}"]
      result << @attribute_list.to_s if @attribute_list
      result.join('')
    end
  end
end
