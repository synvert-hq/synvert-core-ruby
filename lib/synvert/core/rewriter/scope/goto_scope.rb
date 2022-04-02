# frozen_string_literal: true

module Synvert::Core
  # Go to and change its scope to a child node.
  class Rewriter::GotoScope < Rewriter::Scope
    # Initialize a GotoScope.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param child_node_name [Symbol|String] name of child node
    # @yield run on the child node
    def initialize(instance, child_node_name, &block)
      super(instance, &block)
      @child_node_name = child_node_name
    end

    # Go to a child now, then run the block code on the the child node.
    def process
      current_node = @instance.current_node
      return unless current_node

      child_node = current_node
      @child_node_name.to_s.split('.').each do |child_node_name|
        child_node = child_node_name.is_a?(Parser::AST::Node) ? child_node_name : child_node.send(child_node_name)
      end
      @instance.process_with_other_node child_node do
        @instance.instance_eval(&@block)
      end
    end
  end
end
