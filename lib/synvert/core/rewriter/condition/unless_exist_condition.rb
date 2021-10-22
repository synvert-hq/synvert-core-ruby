# frozen_string_literal: true

module Synvert::Core
  # UnlessExistCondition checks if matching node doesn't exist in the node children.
  class Rewriter::UnlessExistCondition < Rewriter::Condition
    # check if none of child node matches the rules.
    def match?
      match = false
      @instance.current_node.recursive_children { |child_node| match ||= child_node&.match?(@rules) }
      !match
    end
  end
end
