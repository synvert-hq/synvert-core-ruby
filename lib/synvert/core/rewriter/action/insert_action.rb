# encoding: utf-8
# frozen_string_literal: true

module Synvert::Core
  # InsertAction to insert code to the top of node body.
  class Rewriter::InsertAction < Rewriter::Action
    DO_LENGTH = " do".length

    # Begin position to insert code.
    #
    # @return [Integer] begin position.
    def begin_pos
      case @node.type
      when :block
        @node.children[1].children.empty? ? @node.children[0].loc.expression.end_pos + DO_LENGTH : @node.children[1].loc.expression.end_pos
      when :class
        @node.children[1] ? @node.children[1].loc.expression.end_pos : @node.children[0].loc.expression.end_pos
      else
        @node.children.last.loc.expression.end_pos
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
      if %i[block class].include? node.type
        ' ' * (node.indent + DEFAULT_INDENT)
      else
        ' ' * node.indent
      end
    end
  end
end
