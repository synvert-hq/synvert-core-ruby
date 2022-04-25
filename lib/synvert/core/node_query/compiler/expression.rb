# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Expression represents a node query expression.
  class Expression
    # Initialize a Expression.
    # @param selector [Synvert::Core::NodeQuery::Compiler::Selector] the selector
    # @param rest [Synvert::Core::NodeQuery::Compiler::Expression] the rest expression
    # @param relationship [Symbol] the relationship between the selector and rest expression, it can be <code>:descendant</code>, <code>:child</code>, <code>:next_sibling</code>, <code>:subsequent_sibling</code> or <code>nil</code>.
    def initialize(selector: nil, rest: nil, relationship: nil)
      @selector = selector
      @rest = rest
      @relationship = relationship
    end

    # Check if the node matches the expression.
    # @param node [Parser::AST::Node] the node
    # @return [Boolean]
    def match?(node)
      !query_nodes(node).empty?
    end

    # Query nodes by the expression.
    #
    # * If relationship is nil, it will match in all recursive child nodes and return matching nodes.
    # * If relationship is :decendant, it will match in all recursive child nodes.
    # * If relationship is :child, it will match in direct child nodes.
    # * If relationship is :next_sibling, it try to match next sibling node.
    # * If relationship is :subsequent_sibling, it will match in all sibling nodes.
    # @param node [Parser::AST::Node] node to match
    # @param descendant_match [Boolean] whether to match in descendant node
    # @return [Array<Parser::AST::Node>] matching nodes.
    def query_nodes(node, descendant_match: true)
      matching_nodes =  find_nodes_without_relationship(node, descendant_match: descendant_match)
      if @relationship.nil?
        return matching_nodes
      end

      expression_nodes = matching_nodes.map do |matching_node|
        case @relationship
        when :descendant
          nodes = []
          matching_node.recursive_children { |child_node| nodes += @rest.query_nodes(child_node, descendant_match: false) }
          nodes
        when :child
          matching_node.children.map { |child_node| @rest.query_nodes(child_node, descendant_match: false) }.flatten
        when :next_sibling
          @rest.query_nodes(matching_node.siblings.first, descendant_match: false)
        when :subsequent_sibling
          matching_node.siblings.map { |sibling_node| @rest.query_nodes(sibling_node, descendant_match: false) }.flatten
        end
      end.flatten
    end

    def to_s
      return @selector.to_s unless @rest

      result = []
      result << @selector if @selector
      case @relationship
      when :child then result << '>'
      when :subsequent_sibling then result << '~'
      when :next_sibling then result << '+'
      end
      result << @rest
      result.map(&:to_s).join(' ')
    end

    private

    def find_nodes_without_relationship(node, descendant_match: true)
      return [node] unless @selector

      nodes = []
      nodes << node if @selector.match?(node)
      if descendant_match
        node.recursive_children do |child_node|
          nodes << child_node if @selector.match?(child_node)
        end
      end
      @selector.filter(nodes)
    end
  end
end