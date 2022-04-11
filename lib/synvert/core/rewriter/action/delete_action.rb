# frozen_string_literal: true

module Synvert::Core
  # DeleteAction deletes child nodes.
  class Rewriter::DeleteAction < Rewriter::Action
    # Initialize a DeleteAction.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param selectors [Array<Symbol, String>] used to select child nodes
    def initialize(instance, *selectors)
      super(instance, nil)
      @selectors = selectors
    end

    # The rewritten code, always empty string.
    def rewritten_code
      ''
    end

    private

    # Calculate the begin and end positions.
    def calculate_position
      @begin_pos = @selectors.map { |selector| @node.child_node_range(selector) }
                             .compact.map(&:begin_pos).min
      @end_pos = @selectors.map { |selector| @node.child_node_range(selector) }
                           .compact.map(&:end_pos).max
      squeeze_spaces
      remove_comma
    end
  end
end
