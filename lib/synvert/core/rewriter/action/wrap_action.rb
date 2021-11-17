# frozen_string_literal: true

module Synvert::Core
  # WrapAction to warp node within a block, class or module.
  #
  # Note: if WrapAction is conflicted with another action (begin_pos and end_pos are overlapped),
  # we have to put those 2 actions into 2 within_file scopes.
  class Rewriter::WrapAction < Rewriter::Action
    def initialize(instance, with:, indent: nil)
      super(instance, with)
      @indent = indent || @node.column
    end

    def calculate_position
      @begin_pos = @node.loc.expression.begin_pos
      @end_pos = @node.loc.expression.end_pos
    end

    # The rewritten source code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      "#{@code}\n#{' ' * @indent}" + @node.to_source.split("\n").map { |line| "  #{line}" }.join("\n") +
        "\n#{' ' * @indent}end"
    end
  end
end
