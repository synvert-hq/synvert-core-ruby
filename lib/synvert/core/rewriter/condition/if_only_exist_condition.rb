# frozen_string_literal: true

module Synvert::Core
  # IfOnlyExistCondition checks if node has only one child node and the child node matches rules.
  class Rewriter::IfOnlyExistCondition < Rewriter::Condition
    private

    # check if only have one child node and the child node matches rules.
    #
    # @return [Boolean]
    def match?
      @instance.current_node.body.size == 1 && @instance.current_node.body.first.match?(@rules)
    end
  end
end
