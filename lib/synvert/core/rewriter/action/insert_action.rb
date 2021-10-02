# frozen_string_literal: true

module Synvert::Core
  # InsertAction to add code to the node.
  class Rewriter::InsertAction < Rewriter::Action
    def initialize(instance, code, at:)
      super(instance, code)
      @at = at
    end

    def calculate_position
      @begin_pos = @at == 'end' ? @node.loc.expression.end_pos : @node.loc.expression.begin_pos
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
