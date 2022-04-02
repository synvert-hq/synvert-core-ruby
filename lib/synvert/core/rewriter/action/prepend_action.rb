# frozen_string_literal: true

module Synvert::Core
  # PrependAction to prepend code to the top of node body.
  class Rewriter::PrependAction < Rewriter::Action
    private

    DO_LENGTH = ' do'.length

    # Calculate the begin and end positions.
    def calculate_position
      @begin_pos =
        case @node.type
        when :block
          if @node.children[1].children.empty?
            @node.children[0].loc.expression.end_pos + DO_LENGTH
          else
            @node.children[1].loc.expression.end_pos
          end
        when :class
          @node.children[1] ? @node.children[1].loc.expression.end_pos : @node.children[0].loc.expression.end_pos
        when :def
          @node.children[1].empty? ? @node.loc.name.end_pos : @node.children[1].loc.expression.end_pos
        when :defs
          @node.children[2].empty? ? @node.loc.name.end_pos : @node.children[2].loc.expression.end_pos
        else
          @node.children.last.loc.expression.end_pos
        end
      @end_pos = @begin_pos
    end

    # Indent of the node.
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      if %i[block class def defs].include?(node.type)
        ' ' * (node.column + DEFAULT_INDENT)
      else
        ' ' * node.column
      end
    end
  end
end
