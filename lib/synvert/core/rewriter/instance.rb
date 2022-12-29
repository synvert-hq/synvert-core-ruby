# frozen_string_literal: true

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
      @actions = []
      @file_path = file_path
      @block = block
      strategy = NodeMutation::Strategy::KEEP_RUNNING
      if rewriter.options[:strategy] == Strategy::ALLOW_INSERT_AT_SAME_POSITION
        strategy |=  NodeMutation::Strategy::ALLOW_INSERT_AT_SAME_POSITION
      end
      NodeMutation.configure({ strategy: strategy })
      rewriter.helpers.each { |helper| singleton_class.send(:define_method, helper[:name], &helper[:block]) }
    end

    # @!attribute [r] file_path
    #   @return file path
    # @!attribute [rw] current_node
    #   @return current ast node
    # @!attribute [r] query_adapter
    #   @return NodeQuery Adapter
    # @!attribute [r] mutation_adapter
    #   @return NodeMutation Adapter
    attr_reader :file_path, :current_node, :query_adapter, :mutation_adapter
    attr_accessor :current_node

    # Process the instance.
    # It finds specified files, for each file, it executes the block code, rewrites the original code,
    # then writes the code back to the original file.
    def process
      puts @file_path if Configuration.show_run_process

      absolute_file_path = File.join(Configuration.root_path, @file_path)
      while true
        source = read_source(absolute_file_path)
        @current_mutation = NodeMutation.new(source)
        @mutation_adapter = NodeMutation.adapter
        @query_adapter = NodeQuery.adapter
        begin
          node = parse_code(@file_path, source)

          process_with_node(node) do
            instance_eval(&@block)
          rescue NoMethodError => e
            puts [
              "error: #{e.message}",
              "file: #{file_path}",
              "source: #{source}",
              "line: #{current_node.line}"
            ].join("\n")
            raise
          end

          result = @current_mutation.process
          if result.affected?
            @rewriter.add_affected_file(file_path)
            write_source(absolute_file_path, result.new_source)
          end
          break unless result.conflicted?
        rescue Parser::SyntaxError
          puts "[Warn] file #{file_path} was not parsed correctly."
          # do nothing, iterate next file
        end
      end
    end

    # Test the instance.
    # It finds specified files, for each file, it executes the block code, tests the original code,
    # then returns the actions.
    def test
      absolute_file_path = File.join(Configuration.root_path, file_path)
      source = read_source(absolute_file_path)
      @current_mutation = NodeMutation.new(source)
      @mutation_adapter = NodeMutation.adapter
      @query_adapter = NodeQuery.adapter
      begin
        node = parse_code(file_path, source)

        process_with_node(node) do
          instance_eval(&@block)
        rescue NoMethodError => e
          puts [
            "error: #{e.message}",
            "file: #{file_path}",
            "source: #{source}",
            "line: #{current_node.line}"
          ].join("\n")
          raise
        end

        result = @current_mutation.test
        result.file_path = file_path
        result
      rescue Parser::SyntaxError
        puts "[Warn] file #{file_path} was not parsed correctly."
        # do nothing, iterate next file
      end
    end


    # Gets current node, it allows to get current node in block code.
    #
    # @return [Parser::AST::Node]
    def node
      @current_node
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

    # It creates a {Synvert::Core::Rewriter::IfOnlyExistCondition} to check
    # if current node has only one child node and the child node matches,
    # if so, then continue operating on each matching ast node.
    # @example
    #   # it { should matcher }
    #   with_node type: 'block', caller: { message: 'it' } do
    #     if_only_exist_node type: 'send', receiver: nil, message: 'should' do
    #     end
    #   end
    # @param nql_or_rules [String|Hash] nql or rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def if_only_exist_node(nql_or_rules, &block)
      Rewriter::IfOnlyExistCondition.new(self, nql_or_rules, &block).process
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
    def insert(code, at: 'end', to: nil)
      @current_mutation.insert(@current_node, code, at: at, to: to)
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
    def insert_after(code, to: nil)
      column = ' ' * NodeMutation.adapter.get_start_loc(@current_node).column
      @current_mutation.insert(@current_node, "\n#{column}#{code}", at: 'end', to: to)
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
    def insert_before(code, to: nil)
      column = ' ' * NodeMutation.adapter.get_start_loc(@current_node).column
      @current_mutation.insert(@current_node, "#{code}\n#{column}", at: 'beginning', to: to)
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
      @current_mutation.actions << Rewriter::ReplaceErbStmtWithExprAction.new(@current_node).process
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
    # @param options [Hash] options.
    # @option and_comma [Boolean] delete extra comma.
    def remove(**options)
      @current_mutation.remove(@current_node, **options)
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
    # @param options [Hash]
    # @option and_comma [Boolean] delete extra comma.
    def delete(*selectors, **options)
      @current_mutation.delete(@current_node, *selectors, **options)
    end

    # It wraps current node with code.
    # @example
    #   # class Foobar
    #   # end
    #   # =>
    #   # module Synvert
    #   #   class Foobar
    #   #   end
    #   # end
    #   within_node type: 'class' do
    #     wrap with: 'module Synvert'
    #   end
    # @param with [String] code need to be wrapped with.
    def wrap(with:)
      @current_mutation.wrap(@current_node, with: with)
    end

    # No operation.
    def noop
      @current_mutation.noop(@current_node)
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

    # Match any value but nil.
    # @example
    #   type: 'hash', nothing_value: 'true', status_value: any_value
    # @return [NodeQuery::AnyValue]
    def any_value
      NodeQuery::AnyValue.new
    end

    private

    # Read file source.
    # @param file_path [String] file path
    # @return [String] file source
    def read_source(file_path)
      source = File.read(file_path, encoding: 'UTF-8')
      source = Engine::Erb.encode(source) if /\.erb$/.match?(file_path)
      source
    end

    # Write file source to file.
    # @param file_path [String] file path
    # @param source [String] file source
    def write_source(file_path, source)
      source = Engine::Erb.decode(source) if /\.erb/.match?(file_path)
      File.write(file_path, source.gsub(/ +\n/, "\n"))
    end

    # Parse code ast node.
    #
    # @param file_path [String] file path
    # @param file_path [String] file path
    # @return [Node] ast node for file
    def parse_code(file_path, source)
      buffer = Parser::Source::Buffer.new file_path
      buffer.source = source

      parser = Parser::CurrentRuby.new
      parser.reset
      parser.parse buffer
    end
  end
end
