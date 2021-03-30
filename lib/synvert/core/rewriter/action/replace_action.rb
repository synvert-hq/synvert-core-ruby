# frozen_string_literal: true

module Synvert::Core
  # ReplaceAction to replace child node with code.
  class Rewriter::ReplaceAction < Rewriter::Action
    def initialize(instance, selector, with:)
      @instance = instance
      @selector = selector
      @code = with
      @node = @instance.current_node
    end

    # Begin position of code to replace.
    #
    # @return [Integer] begin position.
    def begin_pos
      @node.child_node_range(@selector).begin_pos
    end

    # End position of code to replace.
    #
    # @return [Integer] end position.
    def end_pos
      @node.child_node_range(@selector).end_pos
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end
  end
end
