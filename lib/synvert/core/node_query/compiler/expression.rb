# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Expression
    def initialize(selector: nil, expression: nil, relationship: nil)
      @selector = selector
      @expression = expression
      @relationship = relationship
    end

    def filter(nodes)
      @selector.filter(nodes)
    end

    def match?(node)
      !query_nodes(node).empty?
    end

    # If @relationship is nil, it will match in all recursive child nodes and return matching nodes.
    # If @relationship is :decendant, it will match in all recursive child nodes.
    # If @relationship is :child, it will match in direct child nodes.
    # If @relationship is :next_sibling, it try to match next sibling node.
    # If @relationship is :subsequent_sibling, it will match in all sibling nodes.
    # @param node [Parser::AST::Node] node to match
    # @param descendant_match [Boolean] whether to match in descendant nodes, default is true
    def query_nodes(node, descendant_match = true)
      matching_nodes =  find_nodes_without_relationship(node, descendant_match)
      if @relationship.nil?
        return matching_nodes
      end

      expression_nodes = matching_nodes.map do |matching_node|
        case @relationship
        when :descendant
          nodes = []
          matching_node.recursive_children { |child_node| nodes += @expression.query_nodes(child_node, false) }
          nodes
        when :child
          matching_node.children.map { |child_node| @expression.query_nodes(child_node, false) }.flatten
        when :next_sibling
          @expression.query_nodes(matching_node.siblings.first, false)
        when :subsequent_sibling
          matching_node.siblings.map { |sibling_node| @expression.query_nodes(sibling_node, false) }.flatten
        end
      end.flatten
    end

    def to_s
      return @selector.to_s unless @expression

      result = []
      result << @selector if @selector
      case @relationship
      when :child then result << '>'
      when :subsequent_sibling then result << '~'
      when :next_sibling then result << '+'
      end
      result << @expression
      result.map(&:to_s).join(' ')
    end

    private

    def find_nodes_without_relationship(node, descendant_match)
      return [node] unless @selector

      nodes = []
      nodes << node if @selector.match?(node)
      if descendant_match
        node.recursive_children do |child_node|
          nodes << child_node if @selector.match?(child_node)
        end
      end
      filter(nodes)
    end
  end
end