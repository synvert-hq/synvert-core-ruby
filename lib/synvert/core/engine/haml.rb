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
              scan_ruby_statement(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            elsif scanner.scan('=') # it matches ruby expression "  = current_user.login"
              scan_ruby_expression(scanner, new_code, leading_spaces_counts, leading_spaces_count)
            elsif scanner.scan(/[%#\.][a-zA-Z0-9\-_%#\.]+/) # it matches element, id and class "  %span.user"
              new_code << WHITESPACE * scanner.matched.size
              if scanner.scan('{') # it matches attributes "  %span{:class => 'user'}"
                new_code << '{'
                count = 1
                while scanner.scan(/.*?[\{\}]/m)
                  if scanner.matched[-1] == '}'
                    count -= 1
                    new_code << scanner.matched
                    break if count == 0
                  else
                    count += 1
                    new_code << scanner.matched
                  end
                end
              end
              if scanner.scan('=')
                scan_ruby_expression(scanner, new_code, leading_spaces_counts, leading_spaces_count)
              end
            else
              while scanner.scan(/(.*?)(\\*)#\{/)
                if scanner.matched[-3] == '\\'
                  new_code << WHITESPACE * scanner.matched.size
                else
                  count = 1
                  while scanner.scan(/.*?([\{\}])/)
                    if scanner.matched[-1] == '}'
                      count -= 1
                      if count == 0
                        new_code << scanner.matched[0..-2] + ';'
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

              if insert_end?(leading_spaces_counts, leading_spaces_count)
                new_code << END_LINE
              end
              if scanner.scan(/.*?(\z|\n)/)
                new_code << WHITESPACE * scanner.matched.size
              end
            end

            break if scanner.eos?
          end

          new_code << END_LINE unless leading_spaces_counts.empty?
          new_code.join
        end

        private

        def scan_ruby_statement(scanner, new_code, leading_spaces_counts, leading_spaces_count)
          new_code << WHITESPACE
          new_code << scanner.scan(/\s*/)
          keyword = scanner.scan(/\w+/)
          rest = scanner.scan(/.*?(\z|\n)/)
          if insert_end?(leading_spaces_counts, leading_spaces_count, !%w[else elsif when].include?(keyword))
            new_code << END_LINE
          end
          if %w[if unless begin case].include?(keyword) || rest.include?(SPACE_DO_SPACE)
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
          new_code << WHITESPACE
          rest = scanner.scan(/.*?(\z|\n)/)
          if insert_end?(leading_spaces_counts, leading_spaces_count)
            new_code << END_LINE
          end
          if rest.include?(SPACE_DO_SPACE)
            leading_spaces_counts << leading_spaces_count
          end
          new_code << rest

          while rest.rstrip.end_with?(',')
            rest = scanner.scan(/.*?(\z|\n)/)
            new_code << rest
          end
        end
      end
    end
  end
end
