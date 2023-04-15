# frozen_string_literal: true

module Synvert::Core
  module Engine
    # Engine::Elegant provides some helper methods for engines
    # who read block code without end.
    # For those engines, it will try to insert `end\n` when encode,
    # while delete `end\n` when generate_transform_proc.
    module Elegant
      END_LINE = "end\n"
      WHITESPACE = ' '
      SPACE_DO_SPACE = ' do '

      # Generate transform proc, it's used to adjust start and end position of actions.
      # Due to the fact that we insert `end\n` when encode the source code, we need to adjust
      # start and end position of actions to match the original source code.
      # e.g. if end\n exists in position 10, action start position is 20 and end position is 30,
      # then action start position should be 16 and end position should be 26.
      #
      # @param encoded_source [String] encoded source.
      # @return [Proc] transform proc.
      def generate_transform_proc(encoded_source)
        proc do |actions|
          start = 0
          indices = []
          loop do
            index = encoded_source[start..-1].index(END_LINE)
            break unless index

            indices << (start + index)
            start += index + END_LINE.length
          end
          indices.each do |index|
            actions.each do |action|
              action.start -= END_LINE.length if action.start > index
              action.end -= END_LINE.length if action.end > index
            end
          end
        end
      end

      # Check if the current leading_spaces_count is less than or equal to the last leading_spaces_count in leading_spaces_counts.
      # If so, pop the last leading_spaces_count and return true.
      def insert_end?(leading_spaces_counts, current_leading_spaces_count, equal = true)
        operation = equal ? :<= : :<
        if !leading_spaces_counts.empty? && current_leading_spaces_count.send(operation, leading_spaces_counts.last)
          leading_spaces_counts.pop
          true
        else
          false
        end
      end
    end
  end
end