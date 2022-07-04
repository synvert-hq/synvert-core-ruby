# frozen_string_literal: true

module Parser::AST
  # Extend Parser::AST::Node.
  # {https://github.com/whitequark/parser/blob/master/lib/parser/ast/node.rb}
  #
  # Rules
  #
  # Synvert compares ast nodes with key / value pairs, each ast node has
  # multiple attributes, e.g. +receiver+, +message+ and +arguments+, it
  # matches only when all of key / value pairs match.
  #
  # +type: 'send', message: :include, arguments: ['FactoryGirl::Syntax::Methods']+
  #
  # Synvert does comparison based on the value type
  #
  # 1. if value is a symbol, then compares ast node value as symbol, e.g. +message: :include+
  # 2. if value is a string, then compares ast node original source code, e.g. +name: 'Synvert::Application'+
  # 3. if value is a regexp, then compares ast node original source code, e.g. +message: /find_all_by_/+
  # 4. if value is an array, then compares each ast node, e.g. +arguments: ['FactoryGirl::Syntax::Methods']+
  # 5. if value is nil, then check if ast node is nil, e.g. +arguments: [nil]+
  # 6. if value is true or false, then check if ast node is :true or :false, e.g. +arguments: [false]+
  # 7. if value is ast, then compare ast node directly, e.g. +to_ast: Parser::CurrentRuby.parse("self.class.serialized_attributes")+
  #
  # It can also compare nested key / value pairs, like
  #
  # +type: 'send', receiver: { type: 'send', receiver: { type: 'send', message: 'config' }, message: 'active_record' }, message: 'identity_map='+
  #
  # Source Code to Ast Node
  # {https://synvert-playground.xinminlabs.com/ruby}
  class Node
    # Get the file name of node.
    #
    # @return [String] file name.
    def filename
      loc.expression&.source_buffer.name
    end

    # Get the column of node.
    #
    # @return [Integer] column.
    def column
      loc.expression.column
    end

    # Get the line of node.
    #
    # @return [Integer] line.
    def line
      loc.expression.line
    end

    # Match node with rules.
    # It provides some additional keywords to match rules, +any+, +contain+, +not+, +in+, +not_in+, +gt+, +gte+, +lt+, +lte+.
    # @example
    #   type: 'send', arguments: { any: 'Lifo::ShowExceptions' }
    #   type: { in: ['send', 'csend'] }
    #   type: :send, arguments: { length: { gt: 2 } }
    # @param rules [Hash] rules to match.
    # @return true if matches.
    def match?(rules)
      keywords = %i[any contain not in not_in gt gte lt lte]
      flat_hash(rules).keys.all? do |multi_keys|
        last_key = multi_keys.last
        actual = keywords.include?(last_key) ? actual_value(multi_keys[0...-1]) : actual_value(multi_keys)
        expected = expected_value(rules, multi_keys)
        case last_key
        when :any, :contain
          actual.any? { |actual_value| match_value?(actual_value, expected) }
        when :not
          !match_value?(actual, expected)
        when :in
          expected.any? { |expected_value| match_value?(actual, expected_value) }
        when :not_in
          expected.all? { |expected_value| !match_value?(actual, expected_value) }
        when :gt
          actual > expected
        when :gte
          actual >= expected
        when :lt
          actual < expected
        when :lte
          actual <= expected
        else
          match_value?(actual, expected)
        end
      end
    end

    # Strip curly braces for hash.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:str, "bar")))
    #   node.strip_curly_braces # "foo: 'bar'"
    # @return [String]
    def strip_curly_braces
      return to_source unless type == :hash

      to_source.sub(/^{(.*)}$/) { Regexp.last_match(1).strip }
    end

    # Wrap curly braces for hash.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:str, "bar")))
    #   node.wrap_curly_braces # "{ foo: 'bar' }"
    # @return [String]
    def wrap_curly_braces
      return to_source unless type == :hash

      "{ #{to_source} }"
    end

    # Get single quote string.
    # @example
    #   node # s(:str, "foobar")
    #   node.to_single_quote # "'foobar'"
    # @return [String]
    def to_single_quote
      return to_source unless type == :str

      "'#{to_value}'"
    end

    # Convert string to symbol.
    # @example
    #   node # s(:str, "foobar")
    #   node.to_symbol # ":foobar"
    # @return [String]
    def to_symbol
      return to_source unless type == :str

      ":#{to_value}"
    end

    # Convert symbol to string.
    # @example
    #   node # s(:sym, :foobar)
    #   node.to_string # "foobar"
    # @return [String]
    def to_string
      return to_source unless type == :sym

      to_value.to_s
    end

    # Convert lambda {} to -> {}
    # @example
    #   node # s(:block, s(:send, nil, :lambda), s(:args), s(:send, nil, :foobar))
    #   node.to_lambda_literal # "-> { foobar }"
    # @return [String]
    def to_lambda_literal
      if type == :block && caller.type == :send && caller.receiver.nil? && caller.message == :lambda
        new_source = to_source
        if arguments.size > 1
          new_source = new_source[0...arguments.first.loc.expression.begin_pos - 2] + new_source[arguments.last.loc.expression.end_pos + 1..-1]
          new_source = new_source.sub('lambda', "->(#{arguments.map(&:to_source).join(', ')})")
        else
          new_source = new_source.sub('lambda', '->')
        end
        new_source
      else
        to_source
      end
    end

    private

    # Compare actual value with expected value.
    #
    # @param actual [Object] actual value.
    # @param expected [Object] expected value.
    # @return [Boolean]
    # @raise [Synvert::Core::MethodNotSupported] if expected class is not supported.
    def match_value?(actual, expected)
      return true if actual == expected

      case expected
      when Symbol
        if actual.is_a?(Parser::AST::Node)
          actual.to_source == ":#{expected}" || actual.to_source == expected.to_s
        else
          actual.to_sym == expected
        end
      when String
        if actual.is_a?(Parser::AST::Node)
          actual.to_source == expected || actual.to_source == unwrap_quote(expected) ||
            unwrap_quote(actual.to_source) == expected || unwrap_quote(actual.to_source) == unwrap_quote(expected)
        else
          actual.to_s == expected || wrap_quote(actual.to_s) == expected
        end
      when Regexp
        if actual.is_a?(Parser::AST::Node)
          actual.to_source =~ Regexp.new(expected.to_s, Regexp::MULTILINE)
        else
          actual.to_s =~ Regexp.new(expected.to_s, Regexp::MULTILINE)
        end
      when Array
        return false unless expected.length == actual.length

        actual.zip(expected).all? { |a, e| match_value?(a, e) }
      when NilClass
        if actual.is_a?(Parser::AST::Node)
          :nil == actual.type
        else
          actual.nil?
        end
      when Numeric
        if actual.is_a?(Parser::AST::Node)
          actual.children[0] == expected
        else
          actual == expected
        end
      when TrueClass
        :true == actual.type
      when FalseClass
        :false == actual.type
      when Parser::AST::Node
        actual == expected
      when Synvert::Core::Rewriter::AnyValue
        !actual.nil?
      else
        raise Synvert::Core::MethodNotSupported, "#{expected.class} is not handled for match_value?"
      end
    end

    # Convert a hash to flat one.
    #
    # @example
    #   flat_hash(type: 'block', caller: {type: 'send', receiver: 'RSpec'})
    #     # {[:type] => 'block', [:caller, :type] => 'send', [:caller, :receiver] => 'RSpec'}
    # @param h [Hash] original hash.
    # @return flatten hash.
    def flat_hash(h, k = [])
      new_hash = {}
      h.each_pair do |key, val|
        if val.is_a?(Hash)
          new_hash.merge!(flat_hash(val, k + [key]))
        else
          new_hash[k + [key]] = val
        end
      end
      new_hash
    end

    # Get actual value from the node.
    #
    # @param multi_keys [Array<Symbol, String>]
    # @return [Object] actual value.
    def actual_value(multi_keys)
      multi_keys.inject(self) { |n, key| n.send(key) if n }
    end

    # Get expected value from rules.
    #
    # @param rules [Hash]
    # @param multi_keys [Array<Symbol>]
    # @return [Object] expected value.
    def expected_value(rules, multi_keys)
      multi_keys.inject(rules) { |o, key| o[key] }
    end

    # Wrap the string with single or double quote.
    def wrap_quote(string)
      if string.include?("'")
        "\"#{string}\""
      else
        "'#{string}'"
      end
    end

    # Unwrap the quote from the string.
    def unwrap_quote(string)
      if (string[0] == '"' && string[-1] == '"') || (string[0] == "'" && string[-1] == "'")
        string[1...-1]
      else
        string
      end
    end
  end
end
