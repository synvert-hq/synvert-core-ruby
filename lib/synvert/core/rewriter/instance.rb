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
    # @param file_patterns [Array<String>] pattern list to find files, e.g. ['spec/**/*_spec.rb']
    # @yield block code to find nodes, match conditions and rewrite code.
    def initialize(rewriter, file_patterns, &block)
      @rewriter = rewriter
      @actions = []
      @file_patterns = file_patterns
      @block = block
      rewriter.helpers.each { |helper| singleton_class.send(:define_method, helper[:name], &helper[:block]) }
    end

    class << self
      # Get file source.
      #
      # @param file_path [String] file path
      # @return [String] file source
      def file_source(file_path)
        @file_source ||= {}
        @file_source[file_path] ||=
          begin
            source = File.read(file_path, encoding: 'UTF-8')
            source = Engine::ERB.encode(source) if /\.erb$/.match?(file_path)
            source
          end
      end

      # Get file ast.
      #
      # @param file_path [String] file path
      # @return [String] ast node for file
      def file_ast(file_path)
        @file_ast ||= {}
        @file_ast[file_path] ||=
          begin
            buffer = Parser::Source::Buffer.new file_path
            buffer.source = file_source(file_path)

            parser = Parser::CurrentRuby.new
            parser.reset
            parser.parse buffer
          end
      end

      # Write source to file and remove cached file source and ast.
      #
      # @param file_path [String] file path
      # @param source [String] file source
      def write_file(file_path, source)
        source = Engine::ERB.decode(source) if /\.erb/.match?(file_path)
        File.write(file_path, source.gsub(/ +\n/, "\n"))
        @file_source[file_path] = nil
        @file_ast[file_path] = nil
      end

      # Reset file source and ast.
      def reset
        @file_source = {}
        @file_ast = {}
      end
    end

    # @!attribute [rw] current_node
    #   @return current parsing node
    # @!attribute [rw] current_file
    #   @return current filename
    attr_accessor :current_node, :current_file

    # Current file source
    def file_source
      self.class.file_source(current_file)
    end

    # Process the instance.
    # It finds specified files, for each file, it executes the block code, rewrites the original code,
    # then write the code back to the original file.
    def process
      @file_patterns.each do |file_pattern|
        Dir.glob(File.join(Configuration.path, file_pattern)).each do |file_path|
          next if Configuration.skip_files.include?(file_path)

          process_file(file_path)
        end
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

    # Parse +find_node+ dsl, it creates {Synvert::Core::Rewriter::QueryScope} to recursively find matching ast nodes,
    # then continue operating on each matching ast node.
    # @example
    #   # matches FactoryBot.create(:user)
    #   find_node '.send[receiver=FactoryBot][message=create][arguments.size=1]' do
    #   end
    # @param query_string [String] query string to find matching ast nodes.
    # @yield run on the matching nodes.
    # @raise [Synvert::Core::NodeQuery::Compiler::ParseError] if query string is invalid.
    def find_node(query_string, &block)
      Rewriter::QueryScope.new(self, query_string, &block).process
    end

    # Parse +within_node+ dsl, it creates a {Synvert::Core::Rewriter::WithinScope} to recursively find matching ast nodes,
    # then continue operating on each matching ast node.
    # @example
    #   # matches User.find_by_login('test')
    #   with_node type: 'send', message: /^find_by_/ do
    #   end
    # @param rules [Hash] rules to find mathing ast nodes.
    # @param options [Hash] optional
    # @option stop_when_match [Boolean] set if stop when match, default is false
    # @option direct [Boolean] set if find direct matching ast nodes, default is false
    # @yield run on the matching nodes.
    def within_node(rules, options = {}, &block)
      options[:stop_when_match] ||= false
      options[:direct] ||= false
      Rewriter::WithinScope.new(self, rules, options, &block).process
    end

    alias with_node within_node

    # Parse +goto_node+ dsl, it creates a {Synvert::Core::Rewriter::GotoScope} to go to a child node,
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

    # Parse +if_exist_node+ dsl, it creates a {Synvert::Core::Rewriter::IfExistCondition} to check
    # if matching nodes exist in the child nodes, if so, then continue operating on each matching ast node.
    # @example
    #   # Klass.any_instance.stub(:message)
    #   with_node type: 'send', message: 'stub', arguments: { first: { type: { not: 'hash' } } } do
    #     if_exist_node type: 'send', message: 'any_instance' do
    #     end
    #   end
    # @param rules [Hash] rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def if_exist_node(rules, &block)
      Rewriter::IfExistCondition.new(self, rules, &block).process
    end

    # Parse +unless_exist_node+ dsl, it creates a {Synvert::Core::Rewriter::UnlessExistCondition} to check
    # if matching nodes doesn't exist in the child nodes, if so, then continue operating on each matching ast node.
    # @example
    #   # obj.stub(:message)
    #   with_node type: 'send', message: 'stub', arguments: { first: { type: { not: 'hash' } } } do
    #     unless_exist_node type: 'send', message: 'any_instance' do
    #     end
    #   end
    # @param rules [Hash] rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def unless_exist_node(rules, &block)
      Rewriter::UnlessExistCondition.new(self, rules, &block).process
    end

    # Parse +if_only_exist_node+ dsl, it creates a {Synvert::Core::Rewriter::IfOnlyExistCondition} to check
    # if current node has only one child node and the child node matches rules,
    # if so, then continue operating on each matching ast node.
    # @example
    #   # it { should matcher }
    #   with_node type: 'block', caller: { message: 'it' } do
    #     if_only_exist_node type: 'send', receiver: nil, message: 'should' do
    #     end
    #   end
    # @param rules [Hash] rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def if_only_exist_node(rules, &block)
      Rewriter::IfOnlyExistCondition.new(self, rules, &block).process
    end

    # Parse +append+ dsl, it creates a {Synvert::Core::Rewriter::AppendAction} to
    # append the code to the bottom of current node body.
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
      @actions << Rewriter::AppendAction.new(self, code).process
    end

    # Parse +prepend+ dsl, it creates a {Synvert::Core::Rewriter::PrependAction} to
    # prepend the code to the top of current node body.
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
      @actions << Rewriter::PrependAction.new(self, code).process
    end

    # Parse +insert+ dsl, it creates a {Synvert::Core::Rewriter::InsertAction} to insert code.
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
      @actions << Rewriter::InsertAction.new(self, code, at: at, to: to).process
    end

    # Parse +insert_after+ dsl, it creates a {Synvert::Core::Rewriter::InsertAfterAction} to
    # insert the code next to the current node.
    # @example
    #   # Synvert::Application.config.secret_token = "0447aa931d42918bfb934750bb78257088fb671186b5d1b6f9fddf126fc8a14d34f1d045cefab3900751c3da121a8dd929aec9bafe975f1cabb48232b4002e4e"
    #   # =>
    #   # Synvert::Application.config.secret_token = "0447aa931d42918bfb934750bb78257088fb671186b5d1b6f9fddf126fc8a14d34f1d045cefab3900751c3da121a8dd929aec9bafe975f1cabb48232b4002e4e"
    #   # Synvert::Application.config.secret_key_base = "bf4f3f46924ecd9adcb6515681c78144545bba454420973a274d7021ff946b8ef043a95ca1a15a9d1b75f9fbdf85d1a3afaf22f4e3c2f3f78e24a0a188b581df"
    #   with_node type: 'send', message: 'secret_token=' do
    #     insert_after "{{receiver}}.secret_key_base = \"#{SecureRandom.hex(64)}\""
    #   end
    # @param code [String] code need to be inserted.
    def insert_after(code)
      @actions << Rewriter::InsertAfterAction.new(self, code).process
    end

    # Parse +replace_with+ dsl, it creates a {Synvert::Core::Rewriter::ReplaceWithAction} to
    # replace the whole code of current node.
    # @example
    #   # obj.stub(:foo => 1, :bar => 2)
    #   # =>
    #   # allow(obj).to receive_messages(:foo => 1, :bar => 2)
    #   with_node type: 'send', message: 'stub', arguments: { first: { type: 'hash' } } do
    #     replace_with 'allow({{receiver}}).to receive_messages({{arguments}})'
    #   end
    # @param code [String] code need to be replaced with.
    def replace_with(code)
      @actions << Rewriter::ReplaceWithAction.new(self, code).process
    end

    # Parse +replace+ dsl, it creates a {Synvert::Core::Rewriter::ReplaceAction} to
    # replace the code of specified child nodes.
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
      @actions << Rewriter::ReplaceAction.new(self, *selectors, with: with).process
    end

    # Parse +replace_erb_stmt_with_expr+ dsl, it creates a {Synvert::Core::Rewriter::ReplaceErbStmtWithExprAction} to
    # replace erb stmt code to expr code.
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
      @actions << Rewriter::ReplaceErbStmtWithExprAction.new(self).process
    end

    # Parse +remove+ dsl, it creates a {Synvert::Core::Rewriter::RemoveAction} to remove current node.
    # @example
    #   with_node type: 'send', message: { in: %w[puts p] } do
    #     remove
    #   end
    def remove
      @actions << Rewriter::RemoveAction.new(self).process
    end

    # Parse +delete+ dsl, it creates a {Synvert::Core::Rewriter::DeleteAction} to delete child nodes.
    # @example
    #   # FactoryBot.create(...)
    #   # =>
    #   # create(...)
    #   with_node type: 'send', receiver: 'FactoryBot', message: 'create' do
    #     delete :receiver, :dot
    #   end
    # @param selectors [Array<Symbol>] selector names of child node.
    def delete(*selectors)
      @actions << Rewriter::DeleteAction.new(self, *selectors).process
    end

    # Parse +wrap+ dsl, it creates a {Synvert::Core::Rewriter::WrapAction} to
    # wrap current node with code.
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
    # @param indent [Integer, nil] number of whitespaces.
    def wrap(with:, indent: nil)
      @actions << Rewriter::WrapAction.new(self, with: with, indent: indent).process
    end

    # Parse +warn+ dsl, it creates a {Synvert::Core::Rewriter::Warning} to save warning message.
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
    # @return [Synvert::Core::Rewriter::AnyValue]
    def any_value
      Rewriter::AnyValue.new
    end

    private

    # Process one file.
    #
    # @param file_path [String]
    def process_file(file_path)
      begin
        puts file_path if Configuration.show_run_process
        conflict_actions = []
        source = +self.class.file_source(file_path)
        ast = self.class.file_ast(file_path)

        @current_file = file_path

        process_with_node(ast) do
          instance_eval(&@block)
        rescue NoMethodError
          puts @current_node.debug_info
          raise
        end

        if @actions.length > 0
          @actions.sort_by! { |action| [action.begin_pos, action.end_pos] }
          conflict_actions = get_conflict_actions
          @actions.reverse_each do |action|
            source[action.begin_pos...action.end_pos] = action.rewritten_code
          end
          @actions = []

          update_file(file_path, source)
        end
      rescue Parser::SyntaxError
        puts "[Warn] file #{file_path} was not parsed correctly."
        # do nothing, iterate next file
      end while !conflict_actions.empty?
    end

    # It changes source code from bottom to top, and it can change source code twice at the same time,
    # So if there is an overlap between two actions, it removes the conflict actions and operate them in the next loop.
    def get_conflict_actions
      i = @actions.length - 1
      j = i - 1
      conflict_actions = []
      return if i < 0

      begin_pos = @actions[i].begin_pos
      while j > -1
        if begin_pos < @actions[j].end_pos
          conflict_actions << @actions.delete_at(j)
        else
          i = j
          begin_pos = @actions[i].begin_pos
        end
        j -= 1
      end
      conflict_actions
    end

    # It updates a file with new source code.
    #
    # @param file_path [String] the file path
    # @param source [String] the new source code
    def update_file(file_path, source)
      self.class.write_file(file_path, source)
      @rewriter.add_affected_file(file_path)
    end
  end
end
