# encoding: utf-8
# frozen_string_literal: true

module Synvert::Core
  # AppendWithAction to append code to the bottom of node body.

  # Begin position to append code.
  #
  # @return [Integer] begin position.

  class Rewriter::AppendAction < Rewriter::Action
    def begin_pos
      :begin == @node.type ? @node.loc.expression.end_pos : @node.loc.expression.end_pos - @node.indent - 4
    end

    # End position, always same to begin position.
    #
    # @return [Integer] end position.
    def end_pos
      begin_pos
    end

    private

    # Indent of the node.
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      %i[block class].include? node.type ? ' ' * (node.indent + 2) : ' ' * node.indent
    end
  end
end
