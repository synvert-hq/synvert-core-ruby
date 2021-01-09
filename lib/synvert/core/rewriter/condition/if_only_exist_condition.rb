# encoding: utf-8

module Synvert::Core
  # IfExistCondition checks if node has only one child node and the child node matches rules.
  class Rewriter::IfOnlyExistCondition < Rewriter::Condition
    # check if only have one child node and the child node matches rules.
    def match?
      @instance.current_node.body.size == 1 && @instance.current_node.body.first.match?(@rules)
    end
  end
end
