# frozen_string_literal: true

module Synvert::Core
  # IfExistCondition checks if matching node exists in the node children.
  class Rewriter::IfExistCondition < Rewriter::Condition
    # check if any child node matches the rules.
    def match?
      match = false
      @instance.current_node.recursive_children { |child_node| match ||= child_node&.match?(@rules) }
      match
    end
  end
end
