# frozen_string_literal: true

module Synvert::Core
  # WithinScope finds out nodes which match rules, then change its scope to matching node.
  class Rewriter::WithinScope < Rewriter::Scope
    # Initialize a scope
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param rules [Hash]
    # @param options [Hash]
    # @param block [Block]
    def initialize(instance, rules, options = { recursive: true }, &block)
      @instance = instance
      @rules = rules
      @options = options
      @block = block
    end

    # Find out the matching nodes. It checks the current node and iterates all child nodes,
    # then run the block code with each matching node.
    def process
      current_node = @instance.current_node
      return unless current_node

      child_nodes = current_node.is_a?(Parser::AST::Node) ? current_node.children : current_node
      process_with_nodes(child_nodes)
    end

    private

    def process_with_nodes(nodes)
      nodes.compact.select { |node| node.is_a?(Parser::AST::Node) }.each do |node|
        if node.match?(@rules)
          @instance.process_with_node(node) do
            @instance.instance_eval &@block
          end
        end
        process_with_nodes(node.children) if @options[:recursive]
      end
    end
  end
end
