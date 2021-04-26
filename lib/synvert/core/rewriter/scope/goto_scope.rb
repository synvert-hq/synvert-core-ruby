# frozen_string_literal: true

module Synvert::Core
  # Go to and change its scope to a child node.
  class Rewriter::GotoScope < Rewriter::Scope
    # Initialize a scope
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param *child_node_names [Array]
    # @param block [Block]
    def initialize(instance, *child_node_names, &block)
      @instance = instance
      @child_node_names = child_node_names
      @block = block
    end

    # Go to a child now, then run the block code with the the child node.
    def process
      current_node = @instance.current_node
      return unless current_node

      child_node = current_node
      @child_node_names.each do |child_node_name|
        child_node = child_node_name.is_a?(Parser::AST::Node) ? child_node_name : child_node.send(child_node_name)
      end
      @instance.process_with_other_node child_node do
        @instance.instance_eval(&@block)
      end
    end
  end
end
