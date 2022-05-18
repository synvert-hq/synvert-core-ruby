# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Selector used to match nodes, it combines by node type and/or attribute list, plus index or has expression.
  class Selector
    # Initialize a Selector.
    # @param goto_scope [String] goto scope
    # @param relationship [Symbol] the relationship between the selectors, it can be descendant <code>nil</code>, child <code>></code>, next sibling <code>+</code> or subsequent sibing <code>~</code>.
    # @param rest [Synvert::Core::NodeQuery::Compiler::Selector] the rest selector
    # @param basic_selector [Synvert::Core::NodeQuery::Compiler::BasicSelector] the simple selector
    # @param attribute_list [Synvert::Core::NodeQuery::Compiler::AttributeList] the attribute list
    # @param pseudo_class [String] the pseudo class, can be <code>has</code> or <code>not_has</code>
    # @param pseudo_selector [Synvert::Core::NodeQuery::Compiler::Expression] the pseudo selector
    def initialize(goto_scope: nil, relationship: nil, rest: nil, basic_selector: nil, pseudo_class: nil, pseudo_selector: nil)
      @goto_scope = goto_scope
      @relationship = relationship
      @rest = rest
      @basic_selector = basic_selector
      @pseudo_class = pseudo_class
      @pseudo_selector = pseudo_selector
    end

    # Check if node matches the selector.
    # @param node [Parser::AST::Node] the node
    def match?(node)
      node.is_a?(::Parser::AST::Node) &&
        (!@basic_selector || @basic_selector.match?(node)) &&
        match_pseudo_class?(node)
    end

    # Query nodes by the selector.
    #
    # * If relationship is nil, it will match in all recursive child nodes and return matching nodes.
    # * If relationship is decendant, it will match in all recursive child nodes.
    # * If relationship is child, it will match in direct child nodes.
    # * If relationship is next sibling, it try to match next sibling node.
    # * If relationship is subsequent sibling, it will match in all sibling nodes.
    # @param node [Parser::AST::Node] node to match
    # @param descendant_match [Boolean] whether to match in descendant node
    # @return [Array<Parser::AST::Node>] matching nodes.
    def query_nodes(node, descendant_match = true)
      return find_nodes_by_relationship(node) if @relationship

      if node.is_a?(::Array)
        return node.flat_map { |child_node| query_nodes(child_node, descendant_match) }
      end

      return find_nodes_by_goto_scope(node) if @goto_scope

      nodes = []
      nodes << node if match?(node)
      if descendant_match && @basic_selector
        node.recursive_children do |child_node|
          nodes << child_node if match?(child_node)
        end
      end
      nodes
    end

    def to_s
      result = []
      result << "#{@goto_scope} " if @goto_scope
      result << "#{@relationship} " if @relationship
      result << @rest.to_s if @rest
      result << @basic_selector.to_s if @basic_selector
      result << ":#{@pseudo_class}(#{@pseudo_selector})" if @pseudo_class
      result.join('')
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
      nodes = []
      case @relationship
      when '>'
        if node.is_a?(::Array)
          node.each do |child_node|
            nodes << child_node if @rest.match?(child_node)
          end
        else
          node.children.each do |child_node|
            nodes << child_node if @rest.match?(child_node)
          end
        end
      when '+'
        next_sibling = node.siblings.first
        nodes << next_sibling if @rest.match?(next_sibling)
      when '~'
        node.siblings.each do |sibling_node|
          nodes << sibling_node if @rest.match?(sibling_node)
        end
      end
      nodes
    end

    def match_pseudo_class?(node)
      case @pseudo_class
      when 'has'
        !@pseudo_selector.query_nodes(node).empty?
      when 'not_has'
        @pseudo_selector.query_nodes(node).empty?
      else
        true
      end
    end
  end
end
