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
      DO_BLOCK_REGEX = / do(\s|\z|\n)/

      IF_KEYWORDS = %w[if unless begin case for while until]
      ELSE_KEYWORDS = %w[else elsif when in rescue ensure]

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

      def scan_ruby_statement(scanner, new_code, leading_spaces_counts, leading_spaces_count)
        new_code << scanner.scan(/\s*/)
        keyword = scanner.scan(/\w+/)
        rest = scanner.scan(/.*?(\z|\n)/)
        if insert_end?(leading_spaces_counts, leading_spaces_count, !ELSE_KEYWORDS.include?(keyword))
          new_code << END_LINE
        end
        if IF_KEYWORDS.include?(keyword) || rest =~ DO_BLOCK_REGEX
          leading_spaces_counts << leading_spaces_count
        end
        new_code << keyword
        new_code << rest

        while rest.rstrip.end_with?(',')
          rest = scanner.scan(/.*?(\z|\n)/)
          new_code << rest
        end
      end

      def scan_ruby_expression(scanner, new_code, leading_spaces_counts, leading_spaces_count)
        if insert_end?(leading_spaces_counts, leading_spaces_count)
          new_code << END_LINE
        end
        rest = scanner.scan(/.*?(\z|\n)/)
        if rest =~ DO_BLOCK_REGEX
          leading_spaces_counts << leading_spaces_count
        end
        new_code << rest

        while rest.rstrip.end_with?(',')
          rest = scanner.scan(/.*?(\z|\n)/)
          new_code << rest
        end
      end

      def scan_ruby_interpolation_and_plain_text(scanner, new_code, leading_spaces_counts, leading_spaces_count)
        if insert_end?(leading_spaces_counts, leading_spaces_count)
          new_code << END_LINE
        end
        while scanner.scan(/(.*?)(\\*)#\{/) # it matches interpolation "  #{current_user.login}"
          new_code << (WHITESPACE * scanner.matched.size)
          unless scanner.matched[-3] == '\\'
            count = 1
            while scanner.scan(/.*?([\{\}])/)
              if scanner.matched[-1] == '}'
                count -= 1
                if count == 0
                  new_code << (scanner.matched[0..-2] + ';')
                  break
                else
                  new_code << scanner.matched
                end
              else
                count += 1
                new_code << scanner.matched
              end
            end
          end
        end
        if scanner.scan(/.*?\z/)
          new_code << (WHITESPACE * scanner.matched.size)
        end
        if scanner.scan(/.*?\n/)
          new_code << ((WHITESPACE * (scanner.matched.size - 1)) + "\n")
        end
      end
    end
  end
end