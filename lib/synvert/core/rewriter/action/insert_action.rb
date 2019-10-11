# encoding: utf-8
# frozen_string_literal: true

module Synvert::Core
  # InsertAction to insert code to the top of node body.

  # Begin position to insert code.
  #
  # @return [Integer] begin position.

  class Rewriter::InsertAction < Rewriter::Action
    def begin_pos
      insert_position(@node)
    end

    # End position, always same to begin position.
    #
    # @return [Integer] end position.
    def end_pos
      begin_pos
    end

    private

    # Insert position.
    #
    # @return [Integer] insert position.
    def insert_position(node)
      case node.type
      when :block
        if node.children[1].children.empty?
          node.children[0].loc.expression.end_pos + 3
        else
          node.children[1].loc.expression.end_pos
        end
      when :class
        node.children[1] ? node.children[1].loc.expression.end_pos : node.children[0].loc.expression.end_pos
      else
        node.children.last.loc.expression.end_pos
      end
    end

    # Indent of the node.
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      %i[block class].include? node.type ? ' ' * (node.indent + 2) : ' ' * node.indent
    end
  end
end
