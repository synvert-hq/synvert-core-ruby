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
    def query_nodes(node, descendant_match = true)
      return find_nodes_by_goto_scope(node) if @goto_scope

      return find_nodes_by_relationship(node) if @relationship

      matching_nodes = find_nodes_without_relationship(node, descendant_match)
      return matching_nodes if @rest.nil?

      matching_nodes.flat_map { |matching_node| find_nodes_by_rest(matching_node, descendant_match) }

    end

    def to_s
      return @selector.to_s unless @rest

      result = []
      result << @selector.to_s if @selector
      result << "<#{@goto_scope}>" if @goto_scope
      case @relationship
      when :child then result << "> #{@rest}"
      when :subsequent_sibling then result << "~ #{@rest}"
      when :next_sibling then result << "+ #{@rest}"
      when :has then result << ":has(#{@rest})"
      when :not_has then result << ":not_has(#{@rest})"
      else result << @rest.to_s
      end
      result.join(' ')
    end

    private

    # Find nodes by @goto_scope
    # @param node [Parser::AST::Node] node to match
    def find_nodes_by_goto_scope(node)
      @goto_scope.split('.').each { |scope| node = node.send(scope) }
      @rest.query_nodes(node, false)
    end

    # Find ndoes by @relationship
    # @param node [Parser::AST::Node] node to match
    def find_nodes_by_relationship(node)
      case @relationship
      when :child
        if node.is_a?(::Array)
          return node.flat_map { |each_node| find_nodes_by_rest(each_node) }

        else
          return node.children.flat_map { |each_node| find_nodes_by_rest(each_node) }

        end
      when :next_sibling
        return find_nodes_by_rest(node.siblings.first)
      when :subsequent_sibling
        return node.siblings.flat_map { |each_node| find_nodes_by_rest(each_node) }

      when :has
        return @rest.match?(node) ? [node] : []
      when :not_has
        return !@rest.match?(node) ? [node] : []
      end
    end

    # Find nodes by @rest
    # @param node [Parser::AST::Node] node to match
    # @param descendant_match [Boolean] whether to match in descendant node
    def find_nodes_by_rest(node, descendant_match = false)
      @rest.query_nodes(node, descendant_match)
    end

    # Find nodes with nil relationship.
    # @param node [Parser::AST::Node] node to match
    # @param descendant_match [Boolean] whether to match in descendant node
    def find_nodes_without_relationship(node, descendant_match = true)
      if node.is_a?(::Array)
        return node.flat_map { |each_node|
          find_nodes_without_relationship(each_node, descendant_match)
        }
      end

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
