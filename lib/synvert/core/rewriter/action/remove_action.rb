# frozen_string_literal: true

module Synvert::Core
  # RemoveAction to remove current node.
  class Rewriter::RemoveAction < Rewriter::Action
    # Initialize a RemoveAction.
    #
    # @param instance [Synvert::Core::Rewriter::RemoveAction]
    def initialize(instance)
      super(instance, nil)
    end

    # The rewritten code, always empty string.
    def rewritten_code
      ''
    end

    private

    # Calculate the begin the end positions.
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

    # Check if the source code of current node takes the whole line.
    #
    # @return [Boolean]
    def take_whole_line?
      @node.to_source == file_source[start_index...end_index].strip
    end

    # Get the start position of the line
    def start_index
      index = file_source[0..@node.loc.expression.begin_pos].rindex("\n")
      index ? index + "\n".length : @node.loc.expression.begin_pos
    end

    # Get the end position of the line
    def end_index
      index = file_source[@node.loc.expression.end_pos..-1].index("\n")
      index ? @node.loc.expression.end_pos + index + "\n".length : @node.loc.expression.end_pos
    end
  end
end
