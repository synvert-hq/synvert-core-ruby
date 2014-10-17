# encoding: utf-8

module Synvert::Core
  # AppendWithAction to append code to the bottom of node body.
  class Rewriter::AppendAction < Rewriter::Action
    # Begin position to append code.
    #
    # @return [Integer] begin position.
    def begin_pos
      if :begin == @node.type
        @node.loc.expression.end_pos
      else
        @node.loc.expression.end_pos - @node.indent - 4
      end
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
      if [:block, :class].include? node.type
        ' ' * (node.indent + 2)
      else
        ' ' * node.indent
      end
    end
  end
end
