# frozen_string_literal: true

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
      if rewritten_source.include?("\n")
        new_code = []
        rewritten_source.split("\n").each_with_index do |line, index|
          new_code << (index == 0 ? line : indent + line)
        end
        new_code.join("\n")
      else
        rewritten_source
      end
    end

    private

    # Indent of the node
    #
    # @return [String] n times whitesphace
    def indent
      ' ' * @node.column
    end
  end
end
