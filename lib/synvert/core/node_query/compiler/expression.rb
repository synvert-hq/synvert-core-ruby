# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Expression represents a node query expression.
  class Expression
    # Initialize a Expression.
    # @param selector [Synvert::Core::NodeQuery::Compiler::Selector] the selector
    # @param rest [Synvert::Core::NodeQuery::Compiler::Expression] the rest expression
    def initialize(selector: nil, rest: nil)
      @selector = selector
      @rest = rest
    end

    # Check if the node matches the expression.
    # @param node [Parser::AST::Node] the node
    # @return [Boolean]
    def match?(node)
      !query_nodes(node).empty?
    end

    # Query nodes by the selector and the rest expression.
    #
    # @param node [Parser::AST::Node] node to match
    # @return [Array<Parser::AST::Node>] matching nodes.
    def query_nodes(node)
      matching_nodes = @selector.query_nodes(node)
      return matching_nodes if @rest.nil?

      matching_nodes.flat_map do |matching_node|
        @rest.query_nodes(matching_node)
      end
    end

    def to_s
      result = []
      result << @selector.to_s if @selector
      result << @rest.to_s if @rest
      result.join(' ')
    end
  end
end
