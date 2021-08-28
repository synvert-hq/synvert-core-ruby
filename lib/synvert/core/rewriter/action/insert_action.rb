# frozen_string_literal: true

module Synvert::Core
  # InsertAction to add code to the node.
  class Rewriter::InsertAction < Rewriter::Action
    def initialize(instance, code, at:)
      super(instance, code)
      @at = at
    end

    # Begin position to insert code.
    #
    # @return [Integer] begin position.
    def begin_pos
      if @at == 'end'
        @node.loc.expression.end_pos
      else
        @node.loc.expression.begin_pos
      end
    end

    # End position, always same to begin position.
    #
    # @return [Integer] end position.
    def end_pos
      begin_pos
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      rewritten_source
    end
  end
end
