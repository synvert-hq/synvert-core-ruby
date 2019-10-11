# encoding: utf-8

module Synvert::Core
  # ReplaceWithAction to replace code.
  class Rewriter::ReplaceWithAction < Rewriter::Action
    # Begin position of code to replace.
    #
    # @return [Integer] begin position.
    def begin_pos
      @node.loc.expression.begin_pos
    end

    # End position of code to replace.
    #
    # @return [Integer] end position.
    def end_pos
      @node.loc.expression.end_pos
    end

    # The rewritten source code with proper indent.
    #
    # @return [String] rewritten code.
    def rewritten_code
      if rewritten_source.split("\n").length > 1
        new_code = []
        rewritten_source.split("\n").each_with_index do |line, index|
          new_code << (index == 0 || !@options[:autoindent] ? line : indent(@node) + line)
        end
        new_code.join("\n")
      else
        rewritten_source
      end
    end

    private

    # Indent of the node
    #
    # @param node [Parser::AST::Node]
    # @return [String] n times whitesphace
    def indent(node)
      ' ' * node.indent
    end
  end
end
