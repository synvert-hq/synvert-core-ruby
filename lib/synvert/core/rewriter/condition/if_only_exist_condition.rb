# frozen_string_literal: true

module Synvert::Core
  # IfOnlyExistCondition checks if node has only one child node and the child node matches.
  class Rewriter::IfOnlyExistCondition < Rewriter::Condition
    private

    # check if only have one child node and the child node matches.
    #
    # @return [Boolean]
    def match?
      target_node.body.size == 1 && @node_query.match_node?(target_node.body.first)
    end
  end
end
