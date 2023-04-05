# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Haml
      class << self
        END_LINE = "end\n"

        # Encode haml string, leave only ruby code, replace other haml code with whitespace.
        # And insert `end\n` for each if, unless, begin, case to make it a valid ruby code.
        #
        # @param source [String] haml code.
        # @return [String] encoded ruby code.
        def encode(source)
          tab_sizes = []
          lines =
            source.lines.map do |line|
              if line =~ /\A(\s*)(- ?)(.*)/ # match "  - if currenet_user"
                code = (' ' * ($1.size + $2.size)) + $3
                new_line =
                  $3.start_with?('else', 'elsif', 'when') ? code : check_and_insert_end(code, tab_sizes, $1.size)
                tab_sizes.push($1.size) if $3.start_with?('if', 'unless', 'begin', 'case') || $3.include?(' do ')

                new_line
              else
                if line =~ /\A(\s*)([%#\.].*)?=(.*)/ # match "  %span= current_user.login"
                  code = (' ' * ($1.size + ($2 || '').size + 1)) + $3
                  new_line = check_and_insert_end(code, tab_sizes, $1.size)
                  tab_sizes.push($1.size) if line.include?(' do ')
                  new_line
                elsif line =~ /\A(\s*)(.*)/ # match any other line
                  check_and_insert_end(' ' * line.size, tab_sizes, $1.size)
                end
              end
            end
          lines.push(END_LINE) unless tab_sizes.empty?
          lines.join("\n")
        end

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

        private

        # Check if the current tab_size is less than or equal to the last tab_size in tab_sizes.
        # If so, pop the last tab_size and insert "end\n" before code.
        # otherwise, return code.
        def check_and_insert_end(code, tab_sizes, current_tab_size)
          if !tab_sizes.empty? && current_tab_size <= tab_sizes[-1]
            tab_sizes.pop
            "end\n" + code
          else
            code
          end
        end
      end
    end
  end
end
