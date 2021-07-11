# frozen_string_literal: true

module Parser::AST
  # Parser::AST::Node monkey patch.
  class Node
    # Get name node of :class, :module, :const, :mlhs, :def and :defs node.
    #
    # @return [Parser::AST::Node] name node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def name
      case type
      when :class, :module, :def, :arg, :blockarg, :restarg
        children[0]
      when :defs, :const
        children[1]
      when :mlhs
        self
      else
        raise Synvert::Core::MethodNotSupported, "name is not handled for #{debug_info}"
      end
    end

    # Get parent_class node of :class node.
    #
    # @return [Parser::AST::Node] parent_class node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def parent_class
      if :class == type
        children[1]
      else
        raise Synvert::Core::MethodNotSupported, "parent_class is not handled for #{debug_info}"
      end
    end

    # Get parent constant node of :const node.
    #
    # @return [Parser::AST::Node] parent const node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def parent_const
      if :const == type
        children[0]
      else
        raise Synvert::Core::MethodNotSupported, "parent_const is not handled for #{debug_info}"
      end
    end

    # Get receiver node of :send node.
    #
    # @return [Parser::AST::Node] receiver node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def receiver
      if :send == type
        children[0]
      else
        raise Synvert::Core::MethodNotSupported, "receiver is not handled for #{debug_info}"
      end
    end

    # Get message node of :super or :send node.
    #
    # @return [Parser::AST::Node] mesage node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def message
      case type
      when :super, :zsuper
        :super
      when :send
        children[1]
      else
        raise Synvert::Core::MethodNotSupported, "message is not handled for #{debug_info}"
      end
    end

    # Get arguments node of :send, :block or :defined? node.
    #
    # @return [Array<Parser::AST::Node>] arguments node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def arguments
      case type
      when :def, :block
        children[1]
      when :defs
        children[2]
      when :send
        children[2..-1]
      when :defined?
        children
      else
        raise Synvert::Core::MethodNotSupported, "arguments is not handled for #{debug_info}"
      end
    end

    # Get caller node of :block node.
    #
    # @return [Parser::AST::Node] caller node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def caller
      if :block == type
        children[0]
      else
        raise Synvert::Core::MethodNotSupported, "caller is not handled for #{debug_info}"
      end
    end

    # Get body node of :begin or :block node.
    #
    # @return [Array<Parser::AST::Node>] body node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def body
      case type
      when :begin
        children
      when :def, :block, :class
        return [] if children[2].nil?

        :begin == children[2].type ? children[2].body : children[2..-1]
      when :defs
        return [] if children[3].nil?

        :begin == children[3].type ? children[3].body : children[3..-1]
      else
        raise Synvert::Core::MethodNotSupported, "body is not handled for #{debug_info}"
      end
    end

    # Get condition node of :if node.
    #
    # @return [Parser::AST::Node] condition node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def condition
      if :if == type
        children[0]
      else
        raise Synvert::Core::MethodNotSupported, "condition is not handled for #{debug_info}"
      end
    end

    # Get keys node of :hash node.
    #
    # @return [Array<Parser::AST::Node>] keys node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def keys
      if :hash == type
        children.map { |child| child.children[0] }
      else
        raise Synvert::Core::MethodNotSupported, "keys is not handled for #{debug_info}"
      end
    end

    # Get values node of :hash node.
    #
    # @return [Array<Parser::AST::Node>] values node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def values
      if :hash == type
        children.map { |child| child.children[1] }
      else
        raise Synvert::Core::MethodNotSupported, "keys is not handled for #{debug_info}"
      end
    end

    # Test if hash node contains specified key.
    #
    # @param [Object] key value.
    # @return [Boolean] true if specified key exists.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def key?(key)
      if :hash == type
        children.any? { |pair_node| pair_node.key.to_value == key }
      else
        raise Synvert::Core::MethodNotSupported, "key? is not handled for #{debug_info}"
      end
    end

    # Get hash value node according to specified key.
    #
    # @param [Object] key value.
    # @return [Parser::AST::Node] value node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def hash_value(key)
      if :hash == type
        value_node = children.find { |pair_node| pair_node.key.to_value == key }
        value_node&.value
      else
        raise Synvert::Core::MethodNotSupported, "hash_value is not handled for #{debug_info}"
      end
    end

    # Get key node of hash :pair node.
    #
    # @return [Parser::AST::Node] key node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def key
      if :pair == type
        children.first
      else
        raise Synvert::Core::MethodNotSupported, "key is not handled for #{debug_info}"
      end
    end

    # Get value node of hash :pair node.
    #
    # @return [Parser::AST::Node] value node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def value
      if :pair == type
        children.last
      else
        raise Synvert::Core::MethodNotSupported, "value is not handled for #{debug_info}"
      end
    end

    # Return the left value.
    #
    # @return [Parser::AST::Node] variable nodes.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def left_value
      if %i[masgn lvasgn ivasgn].include? type
        children[0]
      else
        raise Synvert::Core::MethodNotSupported, "left_value is not handled for #{debug_info}"
      end
    end

    # Return the right value.
    #
    # @return [Array<Parser::AST::Node>] variable nodes.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def right_value
      if %i[masgn lvasgn ivasgn].include? type
        children[1]
      else
        raise Synvert::Core::MethodNotSupported, "right_value is not handled for #{debug_info}"
      end
    end

    # Return the exact value.
    #
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
      when :array
        children.map(&:to_value)
      when :irange
        (children.first.to_value..children.last.to_value)
      when :begin
        children.first.to_value
      else
        self
      end
    end

    # Respond key value for hash node, e.g.
    #
    # Current node is s(:hash, s(:pair, s(:sym, :number), s(:int, 10)))
    # node.number_value is 10
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

    def to_s
      if :mlhs == type
        "(#{children.map(&:name).join(', ')})"
      end
    end

    def debug_info
      "\n" +
        [
          "file: #{loc.expression.source_buffer.name}",
          "line: #{loc.expression.line}",
          "source: #{to_source}",
          "node: #{inspect}"
        ].join("\n")
    end

    # Get the source code of current node.
    #
    # @return [String] source code.
    def to_source
      loc.expression&.source
    end

    # Get the indent of current node.
    #
    # @return [Integer] indent.
    def indent
      loc.expression.column
    end

    # Get the line of current node.
    #
    # @return [Integer] line.
    def line
      loc.expression.line
    end

    # Get the source range of child node.
    #
    # @param [String] name of child node.
    # @return [Parser::Source::Range] source range of child node.
    def child_node_range(child_name)
      case [type, child_name]
      when %i[block pipes], %i[def parentheses], %i[defs parentheses]
        Parser::Source::Range.new('(string)', arguments.loc.expression.begin_pos, arguments.loc.expression.end_pos)
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
      when %i[send dot]
        loc.dot
      when %i[send message]
        if loc.operator
          Parser::Source::Range.new('(string)', loc.selector.begin_pos, loc.operator.end_pos)
        else
          loc.selector
        end
      else
        if respond_to?(child_name)
          child_node = send(child_name)
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

    # Recursively iterate all child nodes of current node.
    #
    # @yield [child] Gives a child node.
    # @yieldparam child [Parser::AST::Node] child node
    def recursive_children(&block)
      children.each do |child|
        if child.is_a?(Parser::AST::Node)
          yield child
          child.recursive_children(&block)
        end
      end
    end

    # Match current node with rules.
    #
    # @param rules [Hash] rules to match.
    # @return true if matches.
    def match?(rules)
      flat_hash(rules).keys.all? do |multi_keys|
        case multi_keys.last
        when :any, :contain
          actual_values = actual_value(self, multi_keys[0...-1])
          expected = expected_value(rules, multi_keys)
          actual_values.any? { |actual| match_value?(actual, expected) }
        when :not
          actual = actual_value(self, multi_keys[0...-1])
          expected = expected_value(rules, multi_keys)
          !match_value?(actual, expected)
        when :in
          actual = actual_value(self, multi_keys[0...-1])
          expected_values = expected_value(rules, multi_keys)
          expected_values.any? { |expected| match_value?(actual, expected) }
        when :not_in
          actual = actual_value(self, multi_keys[0...-1])
          expected_values = expected_value(rules, multi_keys)
          expected_values.all? { |expected| !match_value?(actual, expected) }
        else
          actual = actual_value(self, multi_keys)
          expected = expected_value(rules, multi_keys)
          match_value?(actual, expected)
        end
      end
    end

    # Get rewritten source code.
    # @example
    #   node.rewritten_source("create({{arguments}})") #=> "create(:post)"
    #
    # @param code [String] raw code.
    # @return [String] rewritten code, replace string in block {{ }} in raw code.
    # @raise [Synvert::Core::MethodNotSupported] if string in block {{ }} does not support.
    def rewritten_source(code)
      code.gsub(/{{(.*?)}}/m) do
        old_code = Regexp.last_match(1)
        if respond_to? old_code.split(/\.|\[/).first
          evaluated = instance_eval old_code
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

    private

    # Compare actual value with expected value.
    #
    # @param actual [Object] actual value.
    # @param expected [Object] expected value.
    # @return [Integer] -1, 0 or 1.
    # @raise [Synvert::Core::MethodNotSupported] if expected class is not supported.
    def match_value?(actual, expected)
      return true if actual == expected

      case expected
      when Symbol
        if actual.is_a?(Parser::AST::Node)
          actual.to_source == ":#{expected}"
        else
          actual.to_sym == expected
        end
      when String
        if actual.is_a?(Parser::AST::Node)
          return true if (Parser::CurrentRuby.parse(expected) == actual rescue nil)

          actual.to_source == expected || (actual.to_source[0] == ':' && actual.to_source[1..-1] == expected) ||
            actual.to_source[1...-1] == expected
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
        actual.nil?
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
    #     #=> {[:type] => 'block', [:caller, :type] => 'send', [:caller, :receiver] => 'RSpec'}
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
    # @param node [Parser::AST::Node]
    # @param multi_keys [Array<Symbol>]
    # @return [Object] actual value.
    def actual_value(node, multi_keys)
      multi_keys.inject(node) { |n, key| n.send(key) if n }
    end

    # Get expected value from rules.
    #
    # @param rules [Hash]
    # @param multi_keys [Array<Symbol>]
    # @return [Object] expected value.
    def expected_value(rules, multi_keys)
      multi_keys.inject(rules) { |o, key| o[key] }
    end

    def wrap_quote(string)
      if string.include?("'")
        "\"#{string}\""
      else
        "'#{string}'"
      end
    end
  end
end
