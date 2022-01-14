# frozen_string_literal: true

module Synvert::Core
  # InsertAction to add code to the node.
  class Rewriter::InsertAction < Rewriter::Action
    def initialize(instance, code, at:, to: nil)
      super(instance, code)
      @at = at
      @to = to
    end

    def calculate_position
      node_range = @to ? @node.child_node_range(@to) : @node.loc.expression
      @begin_pos = @at == 'end' ? node_range.end_pos : node_range.begin_pos
      @end_pos = @begin_pos
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end
  end
end
