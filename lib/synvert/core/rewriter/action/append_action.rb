# frozen_string_literal: true

module Synvert::Core
  # AppendAction appends code to the bottom of node body.
  class Rewriter::AppendAction < Rewriter::Action
    private

    END_LENGTH = "\nend".length

    # Calculate the begin the end positions.
    def calculate_position
      @begin_pos = :begin == @node.type ? @node.loc.expression.end_pos : @node.loc.expression.end_pos - @node.column - END_LENGTH
      @end_pos = @begin_pos
    end

    # Indent of the node.
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      if %i[block class def defs].include? node.type
        ' ' * (node.column + DEFAULT_INDENT)
      else
        ' ' * node.column
      end
    end
  end
end
