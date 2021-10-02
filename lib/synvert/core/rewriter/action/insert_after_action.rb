# frozen_string_literal: true

module Synvert::Core
  # InsertAfterAction to insert code next to the node.
  class Rewriter::InsertAfterAction < Rewriter::Action
    def calculate_position
      @begin_pos = @node.loc.expression.end_pos
      @end_pos = @begin_pos
    end

    private

    # Indent of the node.
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      ' ' * node.column
    end
  end
end
