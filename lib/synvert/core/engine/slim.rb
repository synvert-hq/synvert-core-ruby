# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Slim
      class << self
        include Elegant

        ATTRIBUTES_PAIR = {
          '{' => '}',
          '[' => ']',
          '(' => ')'
        }

        # Encode haml string, leave only ruby code, replace other haml code with whitespace.
        # And insert `end\n` for each if, unless, begin, case to make it a valid ruby code.
        #
        # @param source [String] haml code.
        # @return [String] encoded ruby code.
        def encode(source)
          leading_spaces_counts = []
          new_code = []
          scanner = StringScanner.new(source)
          loop do
            new_code << scanner.scan(/\s*/)
            leading_spaces_count = scanner.matched.size
            if scanner.scan('-') # it matches ruby statement "  - current_user"
              new_code << WHITESPACE
              scan_ruby_statement(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            elsif scanner.scan(/==?/) # it matches ruby expression "  = current_user.login"
              new_code << WHITESPACE * scanner.matched.size
              scan_ruby_expression(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            elsif scanner.scan(/[a-z#\.][a-zA-Z0-9\-_%#\.]*/) # it matches element, id and class "  span.user"
              new_code << WHITESPACE * scanner.matched.size
              ATTRIBUTES_PAIR.each do |start, ending| # it matches attributes in brackets "  span[ class='user' ]"
                scan_matching_wrapper(scanner, new_code, start, ending)
              end
              scan_attributes_between_whitespace(scanner, new_code)
              if scanner.scan(/ ?==?/) # it matches ruby expression "  span= current_user.login"
                new_code << WHITESPACE * scanner.matched.size
                scan_ruby_expression(scanner, new_code, leading_spaces_counts, leading_spaces_count)
              else
                scan_ruby_interpolation_and_plain_text(scanner, new_code, leading_spaces_counts, leading_spaces_count)
              end
            else
              scan_ruby_interpolation_and_plain_text(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            end

            break if scanner.eos?
          end

          while leading_spaces_counts.pop
            new_code << END_LINE
          end
          new_code.join
        end

        private

        def scan_matching_wrapper(scanner, new_code, start, ending)
          if scanner.scan(start) # it matches attributes "  %span[ class='user' ]"
            new_code << WHITESPACE
            count = 1
            while scanner.scan(/.*?[#{Regexp.quote(start)}#{Regexp.quote(ending)}]/m)
              matched = scanner.matched.gsub(/(\A| ).*?=/) { |key| WHITESPACE * key.size }
              if scanner.matched[-1] == ending
                new_code << matched[0..-2] + ';'
                count -= 1
                break if count == 0
              else
                new_code << matched
                count += 1
              end
            end
          end
        end

        def scan_attributes_between_whitespace(scanner, new_code)
          while scanner.scan(/ ?[\w\-_]+==?/) # it matches attributes split by space "  span class='user'"
            new_code << WHITESPACE * scanner.matched.size
            stack = []
            while scanner.scan(/(.*?['"\(\)\[\]\{\}]|.+?\b)/)
              matched = scanner.matched
              new_code << matched
              if ['(', '[', '{'].include?(matched[-1])
                stack << matched[-1]
              elsif [')', ']', '}'].include?(matched[-1])
                stack.pop
              elsif %w['  "].include?(matched[-1])
                stack.last == matched[-1] ? stack.pop : stack << matched[-1]
              end
              break if stack.empty?
            end
            if scanner.scan(' ')
              new_code << ';'
            end
          end
        end
      end
    end
  end
end
