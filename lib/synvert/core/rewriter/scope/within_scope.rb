# encoding: utf-8

module Synvert::Core
  # WithinScope finds out nodes which match rules, then change its scope to matching node.
  class Rewriter::WithinScope < Rewriter::Scope
    # Initialize a scope
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param rules [Hash]
    # @param block [Block]
    def initialize(instance, rules, &block)
      @instance = instance
      @rules = rules
      @block = block
    end

    # Find out the matching nodes. It checks the current node and iterates all child nodes,
    # then run the block code with each matching node.
    def process
      current_node = @instance.current_node
      return unless current_node

      @instance.process_with_node current_node do
        matching_nodes = []
        matching_nodes << current_node if current_node.match? @rules
        current_node.recursive_children do |child_node|
          matching_nodes << child_node if child_node.match? @rules
        end
        matching_nodes.each do |matching_node|
          @instance.process_with_node matching_node do
            @instance.instance_eval &@block
          end
        end
      end
    end
  end
end
