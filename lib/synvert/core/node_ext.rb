# frozen_string_literal: true

module Parser::AST
  # ArgumentsNode allows to handle all args as one node or handle all args as an array.
  class ArgumentsNode
    # Initialize
    #
    # @param node [Parser::AST::Node] args node.
    def initialize(node)
      @node = node
    end

    # If args node responds method itself, call method on args node.
    # If args children (array) responds method,  call method on args children.
    # Otherwise raise method missing error.
    def method_missing(meth, *args, &block)
      if @node.respond_to?(meth)
        @node.send meth, *args, &block
      elsif @node.children.respond_to?(meth)
        @node.children.send meth, *args, &block
      else
        super
      end
    end
  end

  # Parser::AST::Node monkey patch.
  class Node
    # Get name node of :class, :module, :const, :mlhs, :def and :defs node.
    #
    # @return [Parser::AST::Node] name node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def name
      case self.type
      when :class, :module, :def, :arg, :blockarg, :restarg
        self.children[0]
      when :defs, :const
        self.children[1]
      when :mlhs
        self
      else
        raise Synvert::Core::MethodNotSupported, "name is not handled for #{self.debug_info}"
      end
    end

    # Get parent_class node of :class node.
    #
    # @return [Parser::AST::Node] parent_class node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def parent_class
      if :class == self.type
        self.children[1]
      else
        raise Synvert::Core::MethodNotSupported, "parent_class is not handled for #{self.debug_info}"
      end
    end

    # Get parent constant node of :const node.
    #
    # @return [Parser::AST::Node] parent const node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def parent_const
      if :const == self.type
        self.children[0]
      else
        raise Synvert::Core::MethodNotSupported, "parent_const is not handled for #{self.debug_info}"
      end
    end

    # Get receiver node of :send node.
    #
    # @return [Parser::AST::Node] receiver node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def receiver
      if :send == self.type
        self.children[0]
      else
        raise Synvert::Core::MethodNotSupported, "receiver is not handled for #{self.debug_info}"
      end
    end

    # Get message node of :super or :send node.
    #
    # @return [Parser::AST::Node] mesage node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def message
      case self.type
      when :super, :zsuper
        :super
      when :send
        self.children[1]
      else
        raise Synvert::Core::MethodNotSupported, "message is not handled for #{self.debug_info}"
      end
    end

    # Get arguments node of :send, :block or :defined? node.
    #
    # @return [Array<Parser::AST::Node>] arguments node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def arguments
      case self.type
      when :def, :block
        ArgumentsNode.new self.children[1]
      when :defs
        ArgumentsNode.new self.children[2]
      when :send
        self.children[2..-1]
      when :defined?
        self.children
      else
        raise Synvert::Core::MethodNotSupported, "arguments is not handled for #{self.debug_info}"
      end
    end

    # Get caller node of :block node.
    #
    # @return [Parser::AST::Node] caller node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def caller
      if :block == self.type
        self.children[0]
      else
        raise Synvert::Core::MethodNotSupported, "caller is not handled for #{self.debug_info}"
      end
    end

    # Get body node of :begin or :block node.
    #
    # @return [Array<Parser::AST::Node>] body node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def body
      case self.type
      when :begin
        self.children
      when :def, :block
        return [] if self.children[2].nil?

        :begin == self.children[2].type ? self.children[2].body : self.children[2..-1]
      when :defs
        return [] if self.children[3].nil?

        :begin == self.children[3].type ? self.children[3].body : self.children[3..-1]
      else
        raise Synvert::Core::MethodNotSupported, "body is not handled for #{self.debug_info}"
      end
    end

    # Get condition node of :if node.
    #
    # @return [Parser::AST::Node] condition node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def condition
      if :if == self.type
        self.children[0]
      else
        raise Synvert::Core::MethodNotSupported, "condition is not handled for #{self.debug_info}"
      end
    end

    # Get keys node of :hash node.
    #
    # @return [Array<Parser::AST::Node>] keys node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def keys
      if :hash == self.type
        self.children.map { |child| child.children[0] }
      else
        raise Synvert::Core::MethodNotSupported, "keys is not handled for #{self.debug_info}"
      end
    end

    # Get values node of :hash node.
    #
    # @return [Array<Parser::AST::Node>] values node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def values
      if :hash == self.type
        self.children.map { |child| child.children[1] }
      else
        raise Synvert::Core::MethodNotSupported, "keys is not handled for #{self.debug_info}"
      end
    end

    # Test if hash node contains specified key.
    #
    # @param [Object] key value.
    # @return [Boolean] true if specified key exists.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def has_key?(key)
      if :hash == self.type
        self.children.any? { |pair_node| pair_node.key.to_value == key }
      else
        raise Synvert::Core::MethodNotSupported, "has_key? is not handled for #{self.debug_info}"
      end
    end

    # Get hash value node according to specified key.
    #
    # @param [Object] key value.
    # @return [Parser::AST::Node] value node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def hash_value(key)
      if :hash == self.type
        value_node = self.children.find { |pair_node| pair_node.key.to_value == key }
        value_node ? value_node.value : nil
      else
        raise Synvert::Core::MethodNotSupported, "has_key? is not handled for #{self.debug_info}"
      end
    end

    # Get key node of hash :pair node.
    #
    # @return [Parser::AST::Node] key node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def key
      if :pair == self.type
        self.children.first
      else
        raise Synvert::Core::MethodNotSupported, "key is not handled for #{self.debug_info}"
      end
    end

    # Get value node of hash :pair node.
    #
    # @return [Parser::AST::Node] value node.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def value
      if :pair == self.type
        self.children.last
      else
        raise Synvert::Core::MethodNotSupported, "value is not handled for #{self.debug_info}"
      end
    end

    # Return the left value.
    #
    # @return [Parser::AST::Node] variable nodes.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def left_value
      if %i[masgn lvasgn ivasgn].include? self.type
        self.children[0]
      else
        raise Synvert::Core::MethodNotSupported, "left_value is not handled for #{self.debug_info}"
      end
    end

    # Return the right value.
    #
    # @return [Array<Parser::AST::Node>] variable nodes.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def right_value
      if %i[masgn lvasgn ivasgn].include? self.type
        self.children[1]
      else
        raise Synvert::Core::MethodNotSupported, "right_value is not handled for #{self.debug_info}"
      end
    end

    # Return the exact value.
    #
    # @return [Object] exact value.
    # @raise [Synvert::Core::MethodNotSupported] if calls on other node.
    def to_value
      case self.type
      when :int, :str, :sym
        self.children.last
      when :true
        true
      when :false
        false
      when :array
        self.children.map(&:to_value)
      when :irange
        (self.children.first.to_value..self.children.last.to_value)
      when :begin
        self.children.first.to_value
      else
        raise Synvert::Core::MethodNotSupported, "to_value is not handled for #{self.debug_info}"
      end
    end

    def to_s
      if :mlhs == self.type
        "(#{self.children.map(&:name).join(', ')})"
      end
    end

    def debug_info
      "\n" + [
        "file: #{self.loc.expression.source_buffer.name}",
        "line: #{self.loc.expression.line}",
        "source: #{self.to_source}",
        "node: #{self.inspect}"
      ].join("\n")
    end

    # Get the source code of current node.
    #
    # @return [String] source code.
    def to_source
      self.loc.expression&.source
    end

    # Get the indent of current node.
    #
    # @return [Integer] indent.
    def indent
      self.loc.expression.column
    end

    # Get the line of current node.
    #
    # @return [Integer] line.
    def line
      self.loc.expression.line
    end

    # Recursively iterate all child nodes of current node.
    #
    # @yield [child] Gives a child node.
    # @yieldparam child [Parser::AST::Node] child node
    def recursive_children
      self.children.each do |child|
        if Parser::AST::Node === child
          yield child
          child.recursive_children { |c| yield c }
        end
      end
    end

    # Match current node with rules.
    #
    # @param rules [Hash] rules to match.
    # @return true if matches.
    def match?(rules)
      flat_hash(rules).keys.all? do |multi_keys|
        if multi_keys.last == :any
          actual_values = actual_value(self, multi_keys[0...-1])
          expected = expected_value(rules, multi_keys)
          actual_values.any? { |actual| match_value?(actual, expected) }
        elsif multi_keys.last == :not
          actual = actual_value(self, multi_keys[0...-1])
          expected = expected_value(rules, multi_keys)
          !match_value?(actual, expected)
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
        if self.respond_to? old_code.split(/\.|\[/).first
          evaluated = self.instance_eval old_code
          case evaluated
          when Parser::AST::Node
            evaluated.loc.expression.source
          when Array, ArgumentsNode
            if evaluated.size > 0
              file_source = evaluated.first.loc.expression.source_buffer.source
              source = file_source[evaluated.first.loc.expression.begin_pos...evaluated.last.loc.expression.end_pos]
              lines = source.split "\n"
              lines_count = lines.length
              if lines_count > 1 && lines_count == evaluated.size
                new_code = []
                lines.each_with_index { |line, index|
                  new_code << (index == 0 ? line : line[evaluated.first.indent-2..-1])
                }
                new_code.join("\n")
              else
                source
              end
            end
          when String, Symbol
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
      case expected
      when Symbol
        if Parser::AST::Node === actual
          actual.to_source == ":#{expected}"
        else
          actual.to_sym == expected
        end
      when String
        if Parser::AST::Node === actual
          actual.to_source == expected ||
            (actual.to_source[0] == ':' && actual.to_source[1..-1] == expected) ||
            actual.to_source[1...-1] == expected
        else
          actual.to_s == expected
        end
      when Regexp
        if Parser::AST::Node === actual
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
        if Parser::AST::Node === actual
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
      multi_keys.inject(node) { |n, key|
        if n
          key == :source ? n.send(key) : n.send(key)
        end
      }
    end

    # Get expected value from rules.
    #
    # @param rules [Hash]
    # @param multi_keys [Array<Symbol>]
    # @return [Object] expected value.
    def expected_value(rules, multi_keys)
      multi_keys.inject(rules) { |o, key| o[key] }
    end
  end
end
