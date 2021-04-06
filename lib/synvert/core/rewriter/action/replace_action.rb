# frozen_string_literal: true

module Synvert::Core
  # ReplaceAction to replace child node with code.
  class Rewriter::ReplaceAction < Rewriter::Action
    def initialize(instance, *selectors, with:)
      @instance = instance
      @selectors = selectors
      @code = with
      @node = @instance.current_node
    end

    # Begin position of code to replace.
    #
    # @return [Integer] begin position.
    def begin_pos
      @selectors.map { |selector| @node.child_node_range(selector).begin_pos }.min
    end

    # End position of code to replace.
    #
    # @return [Integer] end position.
    def end_pos
      @selectors.map { |selector| @node.child_node_range(selector).end_pos }.max
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end
  end
end
