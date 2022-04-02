# frozen_string_literal: true

module Synvert::Core
  # ReplaceAction to replace child node with code.
  class Rewriter::ReplaceAction < Rewriter::Action
    # Initailize a ReplaceAction.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param selectors [Array<Symbol|String>] used to select child nodes
    # @param with [String] the new code
    def initialize(instance, *selectors, with:)
      super(instance, with)
      @selectors = selectors
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end

    private

    # Calculate the begin the end positions.
    def calculate_position
      @begin_pos = @selectors.map { |selector| @node.child_node_range(selector).begin_pos }.min
      @end_pos = @selectors.map { |selector| @node.child_node_range(selector).end_pos }.max
    end
  end
end
