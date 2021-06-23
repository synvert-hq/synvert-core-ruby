# frozen_string_literal: true

module Synvert::Core
  # AddAction to add code to the node.
  class Rewriter::AddAction < Rewriter::Action
    # Begin position to insert code.
    #
    # @return [Integer] begin position.
    def begin_pos
      @node.loc.expression.end_pos
    end

    # End position, always same to begin position.
    #
    # @return [Integer] end position.
    def end_pos
      begin_pos
    end

    private

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end
  end
end
