# frozen_string_literal: true

module Synvert::Core
  # DeleteAction to delete child nodes.
  class Rewriter::DeleteAction < Rewriter::Action
    def initialize(instance, *selectors)
      super(instance, nil)
      @selectors = selectors
    end

    def calculate_position
      @begin_pos = @selectors.map { |selector| @node.child_node_range(selector) }.compact.map(&:begin_pos).min
      @end_pos = @selectors.map { |selector| @node.child_node_range(selector) }.compact.map(&:end_pos).max
      squeeze_spaces
    end

    # The rewritten code, always empty string.
    def rewritten_code
      ''
    end
  end
end
