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
          leading_spaces_counts = []
          new_code = []
          scanner = StringScanner.new(source)
          loop do
            new_code << scanner.scan(/\s*/)
            leading_spaces_count = scanner.matched.size
            if scanner.scan('-') # it matches ruby statement "  - current_user"
              new_code << WHITESPACE
              scan_ruby_statement(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            elsif scanner.scan('=') # it matches ruby expression "  = current_user.login"
              new_code << WHITESPACE
              scan_ruby_expression(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            elsif scanner.scan(/[%#\.][a-zA-Z0-9\-_%#\.]+/) # it matches element, id and class "  %span.user"
              new_code << (WHITESPACE * scanner.matched.size)
              scan_matching_wrapper(scanner, new_code, '{', '}')
              if scanner.scan('=')
                new_code << WHITESPACE
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
          if scanner.scan(start) # it matches attributes "  %span{:class => 'user'}"
            new_code << start
            count = 1
            while scanner.scan(/.*?[#{Regexp.quote(start)}#{Regexp.quote(ending)}]/m)
              new_code << scanner.matched
              if scanner.matched[-1] == ending
                count -= 1
                break if count == 0
              else
                count += 1
              end
            end
          end
        end
      end
    end
  end
end
