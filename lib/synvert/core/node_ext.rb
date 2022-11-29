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
  # {https://playground.synvert.net/ruby}
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
  end
end
