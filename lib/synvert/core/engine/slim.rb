# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Slim
      class << self
        include Elegant

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
                if line =~ /\A(\s*)(.*)?( ?==?)(.*)/ # match "  span= current_user.login"
                  code = (' ' * ($1.size + ($2 || '').size + $3.size)) + $4
                  new_line = check_and_insert_end(code, tab_sizes, $1.size)
                  tab_sizes.push($1.size) if line.include?(' do ')
                  new_line
                elsif line =~ /\A(\s*)(.*)/ # match any other line
                  new_code = []
                  state = :plain
                  line.each_char do |char|
                    case state
                    when :plain
                      if char == '#'
                        state = :possible_ruby_expression
                      end
                      new_code << ' '
                    when :possible_ruby_expression
                      if char == '{'
                        state = :ruby_expression
                      else
                        state = :plain
                      end
                      new_code << ' '
                    when :ruby_expression
                      if char == '}'
                        state = :plain
                        new_code << ' '
                      else
                        new_code << char
                      end
                    else
                      new_code << ' '
                    end
                  end
                  check_and_insert_end(new_code.join, tab_sizes, $1.size)
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
