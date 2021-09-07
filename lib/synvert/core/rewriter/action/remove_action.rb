# frozen_string_literal: true

module Synvert::Core
  # RemoveAction to remove current node.
  class Rewriter::RemoveAction < Rewriter::Action
    def initialize(instance)
      super(instance, nil)
    end

    # Begin position of code to replace.
    #
    # @return [Integer] begin position.
    def begin_pos
      @node.loc.expression.begin_pos
    end

    # End position of code to replace.
    #
    # @return [Integer] end position.
    def end_pos
      @node.loc.expression.end_pos
    end

    # The rewritten code, always empty string.
    def rewritten_code
      ''
    end
  end
end
