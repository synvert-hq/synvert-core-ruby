# frozen_string_literal: true

module Synvert::Core
  # AppendAction to append code to the bottom of node body.
  class Rewriter::AppendAction < Rewriter::Action
    END_LENGTH = "\nend".length

    def calculate_position
      @begin_pos =
        :begin == @node.type ? @node.loc.expression.end_pos : @node.loc.expression.end_pos - @node.column - END_LENGTH
      @end_pos = @begin_pos
    end

    private

    # Indent of the node.
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      if %i[block class].include? node.type
        ' ' * (node.column + DEFAULT_INDENT)
      else
        ' ' * node.column
      end
    end
  end
end
