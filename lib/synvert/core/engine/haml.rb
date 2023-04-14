# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Haml
      class << self
        include Elegant

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
      end
    end
  end
end
