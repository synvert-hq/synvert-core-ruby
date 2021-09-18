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
    def begin_pos
      if take_whole_line?
        start_index
      else
        pos = @node.loc.expression.begin_pos
        squeeze_spaces(pos, end_pos)
      end
    end

    # End position of code to replace.
    #
    # @return [Integer] end position.
    def end_pos
      if take_whole_line?
        end_index
      else
        @node.loc.expression.end_pos
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
      pos = index ? @node.loc.expression.end_pos + index + "\n".length : @node.loc.expression.end_pos
      squeeze_lines(pos, @node.loc.expression.first_line, @node.loc.expression.last_line)
    end
  end
end
