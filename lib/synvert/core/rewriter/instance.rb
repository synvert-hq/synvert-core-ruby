# frozen_string_literal: true

require 'parser/current'
require 'parser_node_ext'
require 'syntax_tree'
require 'syntax_tree_ext'
require 'prism'
require 'prism_ext'

module Synvert::Core
  # Instance is an execution unit, it finds specified ast nodes,
  # checks if the nodes match some conditions, then add, replace or remove code.
  #
  # One instance can contain one or many {Synvert::Core::Rewriter::Scope} and {Synvert::Rewriter::Condition}.
  class Rewriter::Instance
    include Rewriter::Helper

    # Initialize an Instance.
    #
    # @param rewriter [Synvert::Core::Rewriter]
    # @param file_path [Array<String>]
    # @yield block code to find nodes, match conditions and rewrite code.
    def initialize(rewriter, file_path, &block)
      @rewriter = rewriter
      @current_parser = @rewriter.parser
      @current_visitor = NodeVisitor.new(adapter: @current_parser)
      @actions = []
      @file_path = file_path
      @block = block
      strategy = NodeMutation::Strategy::KEEP_RUNNING
      if rewriter.options[:strategy] == Strategy::ALLOW_INSERT_AT_SAME_POSITION
        strategy |= NodeMutation::Strategy::ALLOW_INSERT_AT_SAME_POSITION
      end
      NodeMutation.configure({ strategy: strategy, tab_width: Configuration.tab_width })
      rewriter.helpers.each { |helper| singleton_class.send(:define_method, helper[:name], &helper[:block]) }
    end

    # @!attribute [r] file_path
    #   @return file path
    # @!attribute [r] current_parser
    #   @return current parser
    # @!attribute [rw] current_node
    #   @return current ast node
    attr_reader :file_path, :current_parser
    attr_accessor :current_node

    # Process the instance.
    # It executes the block code, rewrites the original code,
    # then writes the code back to the original file.
    def process
      puts @file_path if Configuration.show_run_process

      absolute_file_path = File.join(Configuration.root_path, @file_path)
      # It keeps running until no conflict,
      # it will try 5 times at maximum.
      5.times do
        source = read_source(absolute_file_path)
        encoded_source = Engine.encode(File.extname(file_path), source)
        @current_mutation = NodeMutation.new(source, adapter: @current_parser)
        @current_mutation.transform_proc = Engine.generate_transform_proc(File.extname(file_path), encoded_source)
        begin
          node = parse_code(@file_path, encoded_source)

          process_with_node(node) do
            instance_eval(&@block)
          end

          @current_visitor.visit(node, self)

          result = @current_mutation.process
          if result.affected?
            @rewriter.add_affected_file(file_path)
            write_source(absolute_file_path, result.new_source)
          end
          break unless result.conflicted?
        rescue Parser::SyntaxError => e
          if ENV['DEBUG'] == 'true'
            puts "[Warn] file #{file_path} was not parsed correctly."
            puts e.message
          end
          break
        end
      end
    end

    # Test the instance.
    # It executes the block code, tests the original code,
    # then returns the actions.
    def test
      absolute_file_path = File.join(Configuration.root_path, file_path)
      source = read_source(absolute_file_path)
      @current_mutation = NodeMutation.new(source, adapter: @current_parser)
      encoded_source = Engine.encode(File.extname(file_path), source)
      @current_mutation.transform_proc = Engine.generate_transform_proc(File.extname(file_path), encoded_source)
      begin
        node = parse_code(file_path, encoded_source)

        process_with_node(node) do
          instance_eval(&@block)
        end

        @current_visitor.visit(node, self)

        result = Configuration.test_result == 'new_source' ? @current_mutation.process : @current_mutation.test
        result.file_path = file_path
        result
      rescue Parser::SyntaxError => e
        if ENV['DEBUG'] == 'true'
          puts "[Warn] file #{file_path} was not parsed correctly."
          puts e.message
        end
      end
    end

    # Gets current node, it allows to get current node in block code.
    #
    # @return [Parser::AST::Node]
    def node
      @current_node
    end

    # Get current_mutation's adapter.
    #
    # @return [NodeMutation::Adapter]
    def mutation_adapter
      @current_mutation.adapter
    end

    # Set current_node to node and process.
    #
    # @param node [Parser::AST::Node] node set to current_node
    # @yield process
    def process_with_node(node)
      self.current_node = node
      yield
      self.current_node = node
    end

    # Set current_node properly, process and set current_node back to original current_node.
    #
    # @param node [Parser::AST::Node] node set to other_node
    # @yield process
    def process_with_other_node(node)
      original_node = current_node
      self.current_node = node
      yield
      self.current_node = original_node
    end

    #######
    # DSL #
    #######

    # It creates a {Synvert::Core::Rewriter::WithinScope} to recursively find matching ast nodes,
    # then continue operating on each matching ast node.
    # @example
    #   # matches User.find_by_login('test')
    #   with_node type: 'send', message: /^find_by_/ do
    #   end
    #   # matches FactoryBot.create(:user)
    #   with_node '.send[receiver=FactoryBot][message=create][arguments.size=1]' do
    #   end
    # @param nql_or_rules [String|Hash] nql or rules to find mathing ast nodes.
    # @param options [Hash] optional
    # @option including_self [Boolean] set if query the current node, default is true
    # @option stop_at_first_match [Boolean] set if stop at first match, default is false
    # @option recursive [Boolean] set if recursively query child nodes, default is true
    # @yield run on the matching nodes.
    def within_node(nql_or_rules, options = {}, &block)
      Rewriter::WithinScope.new(self, nql_or_rules, options, &block).process
    rescue NodeQueryLexer::ScanError, Racc::ParseError => e
      raise NodeQuery::Compiler::ParseError, "Invalid query string: #{nql_or_rules}"
    end

    alias with_node within_node
    alias find_node within_node

    # It creates a {Synvert::Core::Rewriter::GotoScope} to go to a child node,
    # then continue operating on the child node.
    # @example
    #   # head status: 406
    #   with_node type: 'send', receiver: nil, message: 'head', arguments: { size: 1, first: { type: 'hash' } } do
    #     goto_node 'arguments.first' do
    #     end
    #   end
    # @param child_node_name [Symbol|String] the name of the child nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def goto_node(child_node_name, &block)
      Rewriter::GotoScope.new(self, child_node_name, &block).process
    end

    # It creates a {Synvert::Core::Rewriter::IfExistCondition} to check
    # if matching nodes exist in the child nodes, if so, then continue operating on each matching ast node.
    # @example
    #   # Klass.any_instance.stub(:message)
    #   with_node type: 'send', message: 'stub', arguments: { first: { type: { not: 'hash' } } } do
    #     if_exist_node type: 'send', message: 'any_instance' do
    #     end
    #   end
    # @param nql_or_rules [String|Hash] nql or rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def if_exist_node(nql_or_rules, &block)
      Rewriter::IfExistCondition.new(self, nql_or_rules, &block).process
    end

    # It creates a {Synvert::Core::Rewriter::UnlessExistCondition} to check
    # if matching nodes doesn't exist in the child nodes, if so, then continue operating on each matching ast node.
    # @example
    #   # obj.stub(:message)
    #   with_node type: 'send', message: 'stub', arguments: { first: { type: { not: 'hash' } } } do
    #     unless_exist_node type: 'send', message: 'any_instance' do
    #     end
    #   end
    # @param nql_or_rules [String|Hash] nql or rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def unless_exist_node(nql_or_rules, &block)
      Rewriter::UnlessExistCondition.new(self, nql_or_rules, &block).process
    end

    # It appends the code to the bottom of current node body.
    # @example
    #   # def teardown
    #   #   clean_something
    #   # end
    #   # =>
    #   # def teardown
    #   #   clean_something
    #   #   super
    #   # end
    #   with_node type: 'def', name: 'steardown' do
    #     append 'super'
    #   end
    # @param code [String] code need to be appended.
    def append(code)
      @current_mutation.append(@current_node, code)
    end

    # It prepends the code to the top of current node body.
    # @example
    #   # def setup
    #   #   do_something
    #   # end
    #   # =>
    #   # def setup
    #   #   super
    #   #   do_something
    #   # end
    #   with_node type: 'def', name: 'setup' do
    #     prepend 'super'
    #   end
    # @param code [String] code need to be prepended.
    def prepend(code)
      @current_mutation.prepend(@current_node, code)
    end

    # It inserts code.
    # @example
    #   # open('http://test.com')
    #   # =>
    #   # URI.open('http://test.com')
    #   with_node type: 'send', receiver: nil, message: 'open' do
    #     insert 'URI.', at: 'beginning'
    #   end
    # @param code [String] code need to be inserted.
    # @param at [String] insert position, beginning or end
    # @param to [String] where to insert, if it is nil, will insert to current node.
    # @param and_comma [Boolean] insert extra comma.
    def insert(code, at: 'end', to: nil, and_comma: false)
      @current_mutation.insert(@current_node, code, at: at, to: to, and_comma: and_comma)
    end

    # It inserts the code next to the current node.
    # @example
    #   # Synvert::Application.config.secret_token = "0447aa931d42918bfb934750bb78257088fb671186b5d1b6f9fddf126fc8a14d34f1d045cefab3900751c3da121a8dd929aec9bafe975f1cabb48232b4002e4e"
    #   # =>
    #   # Synvert::Application.config.secret_token = "0447aa931d42918bfb934750bb78257088fb671186b5d1b6f9fddf126fc8a14d34f1d045cefab3900751c3da121a8dd929aec9bafe975f1cabb48232b4002e4e"
    #   # Synvert::Application.config.secret_key_base = "bf4f3f46924ecd9adcb6515681c78144545bba454420973a274d7021ff946b8ef043a95ca1a15a9d1b75f9fbdf85d1a3afaf22f4e3c2f3f78e24a0a188b581df"
    #   with_node type: 'send', message: 'secret_token=' do
    #     insert_after "{{receiver}}.secret_key_base = \"#{SecureRandom.hex(64)}\""
    #   end
    # @param code [String] code need to be inserted.
    # @param to [String] where to insert, if it is nil, will insert to current node.
    # @param and_comma [Boolean] insert extra comma.
    def insert_after(code, to: nil, and_comma: false)
      column = ' ' * @current_mutation.adapter.get_start_loc(@current_node, to).column
      @current_mutation.insert(@current_node, "\n#{column}#{code}", at: 'end', to: to, and_comma: and_comma)
    end

    # It inserts the code previous to the current node.
    # @example
    #   # Synvert::Application.config.secret_token = "0447aa931d42918bfb934750bb78257088fb671186b5d1b6f9fddf126fc8a14d34f1d045cefab3900751c3da121a8dd929aec9bafe975f1cabb48232b4002e4e"
    #   # =>
    #   # Synvert::Application.config.secret_key_base = "bf4f3f46924ecd9adcb6515681c78144545bba454420973a274d7021ff946b8ef043a95ca1a15a9d1b75f9fbdf85d1a3afaf22f4e3c2f3f78e24a0a188b581df"
    #   # Synvert::Application.config.secret_token = "0447aa931d42918bfb934750bb78257088fb671186b5d1b6f9fddf126fc8a14d34f1d045cefab3900751c3da121a8dd929aec9bafe975f1cabb48232b4002e4e"
    #   with_node type: 'send', message: 'secret_token=' do
    #     insert_before "{{receiver}}.secret_key_base = \"#{SecureRandom.hex(64)}\""
    #   end
    # @param code [String] code need to be inserted.
    # @param to [String] where to insert, if it is nil, will insert to current node.
    # @param and_comma [Boolean] insert extra comma.
    def insert_before(code, to: nil, and_comma: false)
      column = ' ' * @current_mutation.adapter.get_start_loc(@current_node, to).column
      @current_mutation.insert(@current_node, "#{code}\n#{column}", at: 'beginning', to: to, and_comma: and_comma)
    end

    # It replaces erb stmt code to expr code.
    # @example
    #   # <% form_for post do |f| %>
    #   # <% end %>
    #   # =>
    #   # <%= form_for post do |f| %>
    #   # <% end %>
    #   with_node type: 'block', caller: { type: 'send', receiver: nil, message: 'form_for' } do
    #     replace_erb_stmt_with_expr
    #   end
    def replace_erb_stmt_with_expr
      absolute_file_path = File.join(Configuration.root_path, @file_path)
      erb_source = read_source(absolute_file_path)
      action = Rewriter::ReplaceErbStmtWithExprAction.new(@current_node, erb_source, adapter: @current_mutation.adapter)
      add_action(action)
    end

    # It replaces the whole code of current node.
    # @example
    #   # obj.stub(:foo => 1, :bar => 2)
    #   # =>
    #   # allow(obj).to receive_messages(:foo => 1, :bar => 2)
    #   with_node type: 'send', message: 'stub', arguments: { first: { type: 'hash' } } do
    #     replace_with 'allow({{receiver}}).to receive_messages({{arguments}})'
    #   end
    # @param code [String] code need to be replaced with.
    def replace_with(code)
      @current_mutation.replace_with(@current_node, code)
    end

    # It replaces the code of specified child nodes.
    # @example
    #   # assert(object.empty?)
    #   # =>
    #   # assert_empty(object)
    #   with_node type: 'send', receiver: nil, message: 'assert', arguments: { size: 1, first: { type: 'send', message: 'empty?', arguments: { size: 0 } } } do
    #     replace :message, with: 'assert_empty'
    #     replace :arguments, with: '{{arguments.first.receiver}}'
    #   end
    # @param selectors [Array<Symbol>] selector names of child node.
    # @param with [String] code need to be replaced with.
    def replace(*selectors, with:)
      @current_mutation.replace(@current_node, *selectors, with: with)
    end

    # It removes current node.
    # @example
    #   with_node type: 'send', message: { in: %w[puts p] } do
    #     remove
    #   end
    # @option and_comma [Boolean] delete extra comma.
    def remove(and_comma: false)
      @current_mutation.remove(@current_node, and_comma: and_comma)
    end

    # It deletes child nodes.
    # @example
    #   # FactoryBot.create(...)
    #   # =>
    #   # create(...)
    #   with_node type: 'send', receiver: 'FactoryBot', message: 'create' do
    #     delete :receiver, :dot
    #   end
    # @param selectors [Array<Symbol>] selector names of child node.
    # @option and_comma [Boolean] delete extra comma.
    def delete(*selectors, and_comma: false)
      @current_mutation.delete(@current_node, *selectors, and_comma: and_comma)
    end

    # It wraps current node with prefix and suffix code.
    # @example
    #   # class Foobar
    #   # end
    #   # =>
    #   # module Synvert
    #   #   class Foobar
    #   #   end
    #   # end
    #   within_node type: 'class' do
    #     wrap prefix: 'module Synvert', suffix: 'end', newline: true
    #   end
    # @param prefix [String] prefix code need to be wrapped with.
    # @param suffix [String] suffix code need to be wrapped with.
    # @param newline [Boolean] if wrap code in newline, default is false
    def wrap(prefix:, suffix:, newline: false)
      @current_mutation.wrap(@current_node, prefix: prefix, suffix: suffix, newline: newline)
    end

    # It indent the code of current node.
    # @example
    #     # class Foobar
    #     # end
    #     # =>
    #     #   class Foobar
    #     #   end
    #     within_node type: 'class' do
    #       indent
    #     end
    def indent(tab_size: 1)
      @current_mutation.indent(@current_node, tab_size: tab_size)
    end

    # No operation.
    def noop
      @current_mutation.noop(@current_node)
    end

    # Group actions.
    # @example
    #     group do
    #       delete :message, :dot
    #       replace 'receiver.caller.message', with: 'flat_map'
    #     end
    def group(&block)
      @current_mutation.group(&block)
    end

    # Add a custom action.
    # @example
    #   remover_action = NodeMutation::RemoveAction.new(node)
    #   add_action(remover_action)
    # @param action [Synvert::Core::Rewriter::Action] action
    def add_action(action)
      @current_mutation.actions << action.process
    end

    # It creates a {Synvert::Core::Rewriter::Warning} to save warning message.
    # @example
    #   within_files 'vendor/plugins' do
    #     warn 'Rails::Plugin is deprecated and will be removed in Rails 4.0. Instead of adding plugins to vendor/plugins use gems or bundler with path or git dependencies.'
    #   end
    # @param message [String] warning message.
    def warn(message)
      @rewriter.add_warning Rewriter::Warning.new(self, message)
    end

    # It adds a callback when visiting an ast node.
    # @example
    #   add_callback :class, at: 'start' do |node|
    #     # do something when visiting class node
    #   end
    # @param node_type [Symbol] node type
    # @param at [String] at start or end
    # @yield block code to run when visiting the node
    def add_callback(node_type, at: 'start', &block)
      @current_visitor.add_callback(node_type, at: at, &block)
    end

    # Wrap str string with single or doulbe quotes based on Configuration.single_quote.
    # @param str [String]
    # @return [String] quoted string
    def wrap_with_quotes(str)
      quote = Configuration.single_quote ? "'" : '"';
      another_quote = Configuration.single_quote ? '"' : "'";
      if str.include?(quote) && !str.include?(another_quote)
        return "#{another_quote}#{str}#{another_quote}"
      end

      escaped_str = str.gsub(quote) { |_char| '\\' + quote }
      quote + escaped_str + quote
    end

    # Add leading spaces before the str according to Configuration.tab_width.
    # @param str [String]
    # @param tab_size [Integer] tab size
    # @return [String]
    def add_leading_spaces(str, tab_size: 1)
      (" " * Configuration.tab_width * tab_size) + str;
    end

    private

    # Read file source.
    # @param file_path [String] file path
    # @return [String] file source
    def read_source(file_path)
      File.read(file_path, encoding: 'UTF-8')
    end

    # Write file source to file.
    # @param file_path [String] file path
    # @param source [String] file source
    def write_source(file_path, source)
      File.write(file_path, source.gsub(/ +\n/, "\n"))
    end

    # Parse code ast node.
    #
    # @param file_path [String] file path
    # @param encoded_source [String] encoded source code
    # @return [Node] ast node for file
    def parse_code(file_path, encoded_source)
      case @current_parser
      when Synvert::SYNTAX_TREE_PARSER
        parse_code_by_syntax_tree(file_path, encoded_source)
      when Synvert::PRISM_PARSER
        parse_code_by_prism(file_path, encoded_source)
      when Synvert::PARSER_PARSER
        parse_code_by_parser(file_path, encoded_source)
      else
        raise Errors::ParserNotSupported.new("Parser #{@current_parser} not supported")
      end
    end

    # Parse code ast node by parser.
    #
    # @param file_path [String] file path
    # @param encoded_source [String] encoded source code
    # @return [Node] ast node for file
    def parse_code_by_parser(file_path, encoded_source)
      buffer = Parser::Source::Buffer.new file_path
      buffer.source = encoded_source

      parser = Parser::CurrentRuby.new
      parser.reset
      parser.parse buffer
    end

    # Parse code ast node by syntax_tree.
    #
    # @param file_path [String] file path
    # @param encoded_source [String] encoded source code
    # @return [Node] ast node for file
    def parse_code_by_syntax_tree(_file_path, encoded_source)
      SyntaxTree.parse(encoded_source).statements
    end

    # Parse code ast node by prism.
    #
    # @param file_path [String] file path
    # @param encoded_source [String] encoded source code
    # @return [Node] ast node for file
    def parse_code_by_prism(_file_path, encoded_source)
      Prism.parse(encoded_source).value.statements
    end
  end
end
