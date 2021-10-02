# frozen_string_literal: true

module Synvert::Core
  # RemoveAction to remove current node.
  class Rewriter::RemoveAction < Rewriter::Action
    def initialize(instance)
      super(instance, nil)
    end

    # Begin position of code to replace.
    #
    # @return [Integer] begin position.
    def calculate_position
      if take_whole_line?
        @begin_pos = start_index
        @end_pos = end_index
        squeeze_lines
      else
        @begin_pos = @node.loc.expression.begin_pos
        @end_pos = @node.loc.expression.end_pos
        squeeze_spaces
        remove_comma
      end
    end

    # The rewritten code, always empty string.
    def rewritten_code
      ''
    end

    private

    def take_whole_line?
      @node.to_source == file_source[start_index...end_index].strip
    end

    def start_index
      index = file_source[0..@node.loc.expression.begin_pos].rindex("\n")
      index ? index + "\n".length : @node.loc.expression.begin_pos
    end

    def end_index
      index = file_source[@node.loc.expression.end_pos..-1].index("\n")
      index ? @node.loc.expression.end_pos + index + "\n".length : @node.loc.expression.end_pos
    end
  end
end
