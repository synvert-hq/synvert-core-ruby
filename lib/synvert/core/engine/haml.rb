# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Haml
      class << self
        # Encode haml string, leave only ruby code, replace other haml code with whitespace.
        #
        # @param source [String] haml code.
        # @return [String] encoded ruby code.
        def encode(source)
          tab_sizes = []
          lines = source.lines.map do |line|
            if line =~ /\A(\s*)(- ?)(.*)/
              if $3.start_with?('if', 'unless', 'begin', 'case') || $3.include?(' do ')
                tab_sizes.push($1.size)
              end
              ' ' * ($1.size + $2.size) + $3
            else
              if line =~ /\A(\s*)([%#\.].*)?=(.*)/ # match "  %span= current_user.login"
                new_line =
                  if !tab_sizes.empty? && tab_sizes[-1] >= $1.size
                    tab_sizes.pop
                    "end\n" + ' ' * ($1.size + ($2 || '').size + 1) + $3
                  else
                    ' ' * ($1.size + ($2 || '').size + 1) + $3
                  end
                if line.include?(' do ')
                  tab_sizes.push($1.size)
                end
                new_line
              elsif line =~ /\A(\s*)(.*)/ # match any other line
                if !tab_sizes.empty? && tab_sizes[-1] >= $1.size
                  tab_sizes.pop
                  "end\n" + ' ' * line.size
                else
                  ' ' * line.size
                end
              end
            end
          end
          unless tab_sizes.empty?
            lines.push("end\n")
          end
          lines.join("\n")
        end
      end
    end
  end
end
