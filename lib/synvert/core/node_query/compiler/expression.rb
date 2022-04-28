# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Expression represents a node query expression.
  class Expression
    # Initialize a Expression.
    # @param selector [Synvert::Core::NodeQuery::Compiler::Selector] the selector
    # @param goto_scope [String] goto scope
    # @param rest [Synvert::Core::NodeQuery::Compiler::Expression] the rest expression
    # @param relationship [Symbol] the relationship between the selector and rest expression, it can be <code>:descendant</code>, <code>:child</code>, <code>:next_sibling</code>, <code>:subsequent_sibling</code> or <code>nil</code>.
    def initialize(selector: nil, goto_scope: nil, rest: nil, relationship: nil)
      @selector = selector
      @goto_scope = goto_scope
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
      if node.is_a?(::Array)
        return node.map { |each_node| query_nodes(each_node, descendant_match: descendant_match) }.flatten
      end

      matching_nodes = find_nodes_without_relationship(node, descendant_match: descendant_match)
      return matching_nodes if @relationship.nil?

      matching_nodes = matching_nodes.map { |matching_node| matching_node.send(@goto_scope) } if @goto_scope
      send("find_nodes_with_#{@relationship}_relationship", matching_nodes)
    end

    def to_s
      return @selector.to_s unless @rest

      result = []
      result << @selector if @selector
      result << "<#{@goto_scope}>" if @goto_scope
      case @relationship
      when :child then result << '>'
      when :subsequent_sibling then result << '~'
      when :next_sibling then result << '+'
      end
      result << @rest
      result.map(&:to_s).join(' ')
    end

    private

    # Find nodes with nil relationship.
    # @param node [Parser::AST::Node] node to match
    # @param descendant_match [Boolean] whether to match in descendant node
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

    # Find nodes with descendant relationship.
    # @param matching_nodes [Array<Parser::AST::Node>] matching nodes
    def find_nodes_with_descendant_relationship(matching_nodes)
      matching_nodes.map do |matching_node|
        nodes = []
        if matching_node.respond_to?(:recursive_children)
          matching_node.recursive_children { |child_node|
            nodes += @rest.query_nodes(child_node, descendant_match: false)
          }
        else # array of nodes
          matching_node.each do |child_node|
            nodes += @rest.query_nodes(child_node, descendant_match: false)
          end
        end
        nodes
      end.flatten
    end

    # Find nodes with child relationship.
    # @param matching_nodes [Array<Parser::AST::Node>] matching nodes
    def find_nodes_with_child_relationship(matching_nodes)
      matching_nodes.map do |matching_node|
        if matching_node.respond_to?(:children)
          matching_node.children.map do |child_node|
            @rest.query_nodes(child_node, descendant_match: false)
          end.flatten
        else # array of nodes
          matching_node.map do |child_node|
            @rest.query_nodes(child_node, descendant_match: false)
          end.flatten
        end
      end.flatten
    end

    # Find nodes with next sibling relationship.
    # @param matching_nodes [Array<Parser::AST::Node>] matching nodes
    def find_nodes_with_next_sibling_relationship(matching_nodes)
      matching_nodes.map do |matching_node|
        @rest.query_nodes(matching_node.siblings.first, descendant_match: false)
      end.flatten
    end

    # Find nodes with subsequent sibling relationship.
    # @param matching_nodes [Array<Parser::AST::Node>] matching nodes
    def find_nodes_with_subsequent_sibling_relationship(matching_nodes)
      matching_nodes.map do |matching_node|
        matching_node.siblings.map do |sibling_node|
          @rest.query_nodes(sibling_node, descendant_match: false)
        end.flatten
      end.flatten
    end
  end
end
