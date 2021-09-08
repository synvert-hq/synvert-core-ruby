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
        @node.loc.expression.begin_pos
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
      file_source[0..@node.loc.expression.begin_pos].rindex("\n") + "\n".length
    end

    def end_index
      file_source[@node.loc.expression.end_pos..-1].index("\n") + @node.loc.expression.end_pos + "\n".length
    end

    def file_source
      @file_source ||= @instance.file_source
    end
  end
end
