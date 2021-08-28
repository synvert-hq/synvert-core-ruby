# frozen_string_literal: true

module Synvert::Core
  # DeleteAction to delete code.
  class Rewriter::DeleteAction < Rewriter::Action
    def initialize(instance, *selectors)
      super(instance, nil)
      @selectors = selectors
    end

    # Begin position of code to delete.
    #
    # @return [Integer] begin position.
    def begin_pos
      @selectors.map { |selector| @node.child_node_range(selector) }.compact.map(&:begin_pos).min
    end

    # End position of code to delete.
    #
    # @return [Integer] end position.
    def end_pos
      @selectors.map { |selector| @node.child_node_range(selector) }.compact.map(&:end_pos).max
    end

    # The rewritten code, always empty string.
    def rewritten_code
      ''
    end
  end
end
