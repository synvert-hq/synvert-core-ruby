# frozen_string_literal: true

module Synvert::Core
  # InsertAction to add code to the node.
  class Rewriter::InsertAction < Rewriter::Action
    # Initialize an InsertAction.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param code [String] to be inserted
    # @param at [String] position to insert, beginning or end
    # @param to [<Symbol|String>] name of child node
    def initialize(instance, code, at: 'end', to: nil)
      super(instance, code)
      @at = at
      @to = to
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end

    private

    # Calculate the begin and end positions.
    def calculate_position
      node_range = @to ? @node.child_node_range(@to) : @node.loc.expression
      @begin_pos = @at == 'end' ? node_range.end_pos : node_range.begin_pos
      @end_pos = @begin_pos
    end
  end
end
