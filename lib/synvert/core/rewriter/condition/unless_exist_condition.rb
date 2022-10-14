# frozen_string_literal: true

module Synvert::Core
  # UnlessExistCondition checks if matching node doesn't exist in the node children.
  class Rewriter::UnlessExistCondition < Rewriter::Condition
    private

    # check if none of child node matches.
    #
    # return [Boolean]
    def match?
      @node_query.query_nodes(target_node, including_self: false, stop_at_first_match: true).size == 0
    end
  end
end
