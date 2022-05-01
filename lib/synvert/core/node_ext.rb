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
    TYPE_CHILDREN = {
      and: %i[left_value right_value],
      arg: %i[name],
      begin: %i[body],
      block: %i[caller arguments body],
      blockarg: %i[name],
      const: %i[parent_const name],
      class: %i[name parent_class body],
      csend: %i[receiver message arguments],
      cvasgn: %i[left_value right_value],
      cvar: %i[name],
      def: %i[name arguments body],
      definded?: %i[arguments],
      defs: %i[self name arguments body],
      hash: %i[pairs],
      ivasgn: %i[left_value right_value],
      ivar: %i[name],
      lvar: %i[name],
      lvasgn: %i[left_value right_value],
      masgn: %i[left_value right_value],
      module: %i[name body],
      or: %i[left_value right_value],
      or_asgn: %i[left_value right_value],
      pair: %i[key value],
      restarg: %i[name],
      send: %i[receiver message arguments],
      super: %i[arguments],
      zsuper: %i[]
    }

    # Initialize a Node.
    #
    # It extends {Parser::AST::Node} and set parent for its child nodes.
    def initialize(type, children = [], properties = {})
      @mutable_attributes = {}
      super
      # children could be nil for s(:array)
      Array(children).each do |child_node|
        if child_node.is_a?(Parser::AST::Node)
          child_node.parent = self
        end
      end
    end

    # Get the parent node.
    # @return [Parser::AST::Node] parent node.
    def parent
      @mutable_attributes[:parent]
    end

    # Set the parent node.
    # @param node [Parser::AST::Node] parent node.
    def parent=(node)
      @mutable_attributes[:parent] = node
    end

    # Get the sibling nodes.
    # @return [Array<Parser::AST::Node>] sibling nodes.
    def siblings
      index = parent.children.index(self)
      parent.children[index + 1..]
    end

    # Dyamically defined method
    # caller, key, left_value, message, name, pairs, parent_class, parent_const, receivr, rgith_value and value.
    # based on const TYPE_CHILDREN.
    %i[
      caller
      key
      left_value
      message
      name
      pairs
      parent_class
      parent_const
      receiver
      right_value
      value
    ].each do |method_name|
      define_method(method_name) do
        index = TYPE_CHILDREN[type]&.index(method_name)
        return children[index] if index

        raise Synvert::Core::MethodNotSupported, "#{method_name} is not handled for #{debug_info}"
      end
    end

    # Return the left value of node.
    # It supports :and, :cvagn, :lvasgn, :masgn, :or and :or_asgn nodes.
    # @example
    #   node # s(:or_asgn, s(:lvasgn, :a), s(:int, 1))
    #   node.left_value # :a
    # @return [Parser::AST::Node] left value of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def left_value
      return children[0].children[0] if type == :or_asgn

      index = TYPE_CHILDREN[type]&.index(:left_value)
      return children[index] if index

      raise Synvert::Core::MethodNotSupported, "#{left_value} is not handled for #{debug_info}"
    end

    # Get arguments of node.
    # It supports :block, :csend, :def, :defined?, :defs and :send nodes.
    # @example
    #   node # s(:send, s(:const, nil, :FactoryGirl), :create, s(:sym, :post), s(:hash, s(:pair, s(:sym, :title), s(:str, "post"))))
    #   node.arguments # [s(:sym, :post), s(:hash, s(:pair, s(:sym, :title), s(:str, "post")))]
    # @return [Array<Parser::AST::Node>] arguments of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def arguments
      case type
      when :def, :block
        children[1].children
      when :defs
        children[2].children
      when :send, :csend
        children[2..-1]
      when :defined?
        children
      else
        raise Synvert::Core::MethodNotSupported, "arguments is not handled for #{debug_info}"
      end
    end

    # Get body of node.
    # It supports :begin, :block, :class, :def, :defs and :module node.
    # @example
    #   node # s(:block, s(:send, s(:const, nil, :RSpec), :configure), s(:args, s(:arg, :config)), s(:send, nil, :include, s(:const, s(:const, nil, :EmailSpec), :Helpers)))
    #   node.body # [s(:send, nil, :include, s(:const, s(:const, nil, :EmailSpec), :Helpers))]
    # @return [Array<Parser::AST::Node>] body of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def body
      case type
      when :begin
        children
      when :def, :block, :class, :module
        return [] if children[2].nil?

        :begin == children[2].type ? children[2].body : children[2..-1]
      when :defs
        return [] if children[3].nil?

        :begin == children[3].type ? children[3].body : children[3..-1]
      else
        raise Synvert::Core::MethodNotSupported, "body is not handled for #{debug_info}"
      end
    end

    # Get condition of node.
    # It supports :if node.
    # @example
    #   node # s(:if, s(:defined?, s(:const, nil, :Bundler)), nil, nil)
    #   node.condition # s(:defined?, s(:const, nil, :Bundler))
    # @return [Parser::AST::Node] condition of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def condition
      if :if == type
        children[0]
      else
        raise Synvert::Core::MethodNotSupported, "condition is not handled for #{debug_info}"
      end
    end

    # Get keys of :hash node.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
    #   node.keys # [s(:sym, :foo), s(:str, "foo")]
    # @return [Array<Parser::AST::Node>] keys of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def keys
      if :hash == type
        children.map { |child| child.children[0] }
      else
        raise Synvert::Core::MethodNotSupported, "keys is not handled for #{debug_info}"
      end
    end

    # Get values of :hash node.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)), s(:pair, s(:str, "foo"), s(:str, "bar")))
    #   node.values # [s(:sym, :bar), s(:str, "bar")]
    # @return [Array<Parser::AST::Node>] values of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def values
      if :hash == type
        children.map { |child| child.children[1] }
      else
        raise Synvert::Core::MethodNotSupported, "keys is not handled for #{debug_info}"
      end
    end

    # Check if :hash node contains specified key.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)))
    #   node.key?(:foo) # true
    # @param [Symbol, String] key value.
    # @return [Boolean] true if specified key exists.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def key?(key)
      if :hash == type
        children.any? { |pair_node| pair_node.key.to_value == key }
      else
        raise Synvert::Core::MethodNotSupported, "key? is not handled for #{debug_info}"
      end
    end

    # Get :hash value node according to specified key.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)))
    #   node.hash_value(:foo) # s(:sym, :bar)
    # @param [Symbol, String] key value.
    # @return [Parser::AST::Node] hash value of node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def hash_value(key)
      if :hash == type
        value_node = children.find { |pair_node| pair_node.key.to_value == key }
        value_node&.value
      else
        raise Synvert::Core::MethodNotSupported, "hash_value is not handled for #{debug_info}"
      end
    end

    # Return the exact value of node.
    # It supports :array, :begin, :erange, :false, :float, :irange, :int, :str, :sym and :true nodes.
    # @example
    #   node # s(:array, s(:str, "str"), s(:sym, :str))
    #   node.to_value # ['str', :str]
    # @return [Object] exact value.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def to_value
      case type
      when :int, :float, :str, :sym
        children.last
      when :true
        true
      when :false
        false
      when :nil
        nil
      when :array
        children.map(&:to_value)
      when :irange
        (children.first.to_value..children.last.to_value)
      when :erange
        (children.first.to_value...children.last.to_value)
      when :begin
        children.first.to_value
      else
        self
      end
    end

    # Respond key value and source for hash node, e.g.
    # @example
    #   node # s(:hash, s(:pair, s(:sym, :foo), s(:sym, :bar)))
    #   node.foo_value # :bar
    #   node.foo_source # ":bar"
    def method_missing(method_name, *args, &block)
      if :args == type && children.respond_to?(method_name)
        return children.send(method_name, *args, &block)
      elsif :hash == type && method_name.to_s.include?('_value')
        key = method_name.to_s.sub('_value', '')
        return hash_value(key.to_sym)&.to_value if key?(key.to_sym)
        return hash_value(key.to_s)&.to_value if key?(key.to_s)

        return nil
      elsif :hash == type && method_name.to_s.include?('_source')
        key = method_name.to_s.sub('_source', '')
        return hash_value(key.to_sym)&.to_source if key?(key.to_sym)
        return hash_value(key.to_s)&.to_source if key?(key.to_s)

        return nil
      end

      super
    end

    def respond_to_missing?(method_name, *args)
      if :args == type && children.respond_to?(method_name)
        return true
      elsif :hash == type && method_name.to_s.include?('_value')
        key = method_name.to_s.sub('_value', '')
        return true if key?(key.to_sym) || key?(key.to_s)
      elsif :hash == type && method_name.to_s.include?('_source')
        key = method_name.to_s.sub('_source', '')
        return true if key?(key.to_sym) || key?(key.to_s)
      end

      super
    end

    # Return the debug info.
    #
    # @return [String] file, line, source and node.
    def debug_info
      "\n" +
        [
          "file: #{loc.expression.source_buffer.name}",
          "line: #{loc.expression.line}",
          "source: #{to_source}",
          "node: #{inspect}"
        ].join("\n")
    end

    # Get the file name of node.
    #
    # @return [String] file name.
    def filename
      loc.expression&.source_buffer.name
    end

    # Get the source code of node.
    #
    # @return [String] source code.
    def to_source
      loc.expression&.source
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

    # Get child node by the name.
    #
    # @param child_name [String] name of child node.
    # @return [Parser::AST::Node] the child node.
    def child_node_by_name(child_name)
      direct_child_name, nested_child_name = child_name.to_s.split('.', 2)
      if respond_to?(direct_child_name)
        child_node = send(direct_child_name)

        return child_node.child_node_by_name(nested_child_name) if nested_child_name

        return nil if child_node.nil?

        return child_node if child_node.is_a?(Parser::AST::Node)

        return child_node
      end

      raise Synvert::Core::MethodNotSupported,
            "child_node_by_name is not handled for #{debug_info}, child_name: #{child_name}"
    end

    # Get the source range of child node.
    #
    # @param child_name [String] name of child node.
    # @return [Parser::Source::Range] source range of child node.
    def child_node_range(child_name)
      case [type, child_name.to_sym]
      when %i[block pipes], %i[def parentheses], %i[defs parentheses]
        Parser::Source::Range.new(
          '(string)',
          arguments.first.loc.expression.begin_pos - 1,
          arguments.last.loc.expression.end_pos + 1
        )
      when %i[block arguments], %i[def arguments], %i[defs arguments]
        Parser::Source::Range.new(
          '(string)',
          arguments.first.loc.expression.begin_pos,
          arguments.last.loc.expression.end_pos
        )
      when %i[class name], %i[def name], %i[defs name]
        loc.name
      when %i[defs dot]
        loc.operator
      when %i[defs self]
        Parser::Source::Range.new('(string)', loc.operator.begin_pos - 'self'.length, loc.operator.begin_pos)
      when %i[send dot], %i[csend dot]
        loc.dot
      when %i[send message], %i[csend message]
        if loc.operator
          Parser::Source::Range.new('(string)', loc.selector.begin_pos, loc.operator.end_pos)
        else
          loc.selector
        end
      when %i[send parentheses], %i[csend parentheses]
        if loc.begin && loc.end
          Parser::Source::Range.new('(string)', loc.begin.begin_pos, loc.end.end_pos)
        end
      else
        direct_child_name, nested_child_name = child_name.to_s.split('.', 2)
        if respond_to?(direct_child_name)
          child_node = send(direct_child_name)

          return child_node.child_node_range(nested_child_name) if nested_child_name

          return nil if child_node.nil?

          if child_node.is_a?(Parser::AST::Node)
            return(
              Parser::Source::Range.new(
                '(string)',
                child_node.loc.expression.begin_pos,
                child_node.loc.expression.end_pos
              )
            )
          end

          # arguments
          return nil if child_node.empty?

          return(
            Parser::Source::Range.new(
              '(string)',
              child_node.first.loc.expression.begin_pos,
              child_node.last.loc.expression.end_pos
            )
          )
        end

        raise Synvert::Core::MethodNotSupported,
              "child_node_range is not handled for #{debug_info}, child_name: #{child_name}"
      end
    end

    # Recursively iterate all child nodes of node.
    #
    # @yield [child] Gives a child node.
    # @yieldparam child [Parser::AST::Node] child node
    def recursive_children(&block)
      children.each do |child|
        if child.is_a?(Parser::AST::Node)
          stop = yield child
          child.recursive_children(&block) unless stop == :stop
        end
      end
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

    # Get rewritten source code.
    # @example
    #   node.rewritten_source("create({{arguments}})") # "create(:post)"
    # @param code [String] raw code.
    # @return [String] rewritten code, replace string in block !{{ }} in raw code.
    # @raise [Synvert::Core::MethodNotSupported] if string in block !{{ }} does not support.
    def rewritten_source(code)
      code.gsub(/{{(.*?)}}/m) do
        old_code = Regexp.last_match(1)
        if respond_to?(old_code.split('.').first)
          evaluated = child_node_by_name(old_code)
          case evaluated
          when Parser::AST::Node
            if evaluated.type == :args
              evaluated.loc.expression.source[1...-1]
            else
              evaluated.loc.expression.source
            end
          when Array
            if evaluated.size > 0
              file_source = evaluated.first.loc.expression.source_buffer.source
              source = file_source[evaluated.first.loc.expression.begin_pos...evaluated.last.loc.expression.end_pos]
              lines = source.split "\n"
              lines_count = lines.length
              if lines_count > 1 && lines_count == evaluated.size
                new_code = []
                lines.each_with_index { |line, index|
                  new_code << (index == 0 ? line : line[evaluated.first.indent - 2..-1])
                }
                new_code.join("\n")
              else
                source
              end
            end
          when String, Symbol, Integer, Float
            evaluated
          when NilClass
            'nil'
          else
            raise Synvert::Core::MethodNotSupported, "rewritten_source is not handled for #{evaluated.inspect}"
          end
        else
          "{{#{old_code}}}"
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

    # Convert node to a hash, so that it can be converted to a json.
    def to_hash
      result = { type: type }
      if TYPE_CHILDREN[type]
        TYPE_CHILDREN[type].each do |key|
          value = send(key)
          result[key] =
            case value
            when Array
              value.map { |v| v.respond_to?(:to_hash) ? v.to_hash : v }
            when Parser::AST::Node
              value.to_hash
            else
              value
            end
        end
      else
        result[:children] = children.map { |c| c.respond_to?(:to_hash) ? c.to_hash : c }
      end
      result
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
