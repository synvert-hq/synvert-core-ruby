# frozen_string_literal: true

module Synvert::Core
  # Instance is an execution unit, it finds specified ast nodes,
  # checks if the nodes match some conditions, then add, replace or remove code.
  #
  # One instance can contains one or many [Synvert::Core::Rewriter::Scope] and [Synvert::Rewriter::Condition].
  class Rewriter::Instance
    include Rewriter::Helper

    class << self
      # Cached file source.
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

      # Cached file ast.
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

      # Reset cached file source and ast.
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

    # Initialize an instance.
    #
    # @param rewriter [Synvert::Core::Rewriter]
    # @param file_patterns [Array<String>] pattern list to find files, e.g. ['spec/**/*_spec.rb']
    # @param block [Block] block code to find nodes, match conditions and rewrite code.
    # @return [Synvert::Core::Rewriter::Instance]
    def initialize(rewriter, file_patterns, &block)
      @rewriter = rewriter
      @actions = []
      @file_patterns = file_patterns
      @block = block
      rewriter.helpers.each { |helper| singleton_class.send(:define_method, helper[:name], &helper[:block]) }
    end

    # Process the instance.
    # It finds all files, for each file, it executes the block code, gets all rewrite actions,
    # and rewrite source code back to original file.
    def process
      @file_patterns.each do |file_pattern|
        Dir.glob(File.join(Configuration.path, file_pattern)).each do |file_path|
          next if Configuration.skip_files.include? file_path

          begin
            puts file_path if Configuration.show_run_process
            conflict_actions = []
            source = +self.class.file_source(file_path)
            ast = self.class.file_ast(file_path)

            @current_file = file_path

            process_with_node ast do
              begin
                instance_eval(&@block)
              rescue NoMethodError
                puts @current_node.debug_info
                raise
              end
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

    # Parse within_node dsl, it creates a [Synvert::Core::Rewriter::WithinScope] to find recursive matching ast nodes,
    # then continue operating on each matching ast node.
    #
    # @param rules [Hash] rules to find mathing ast nodes.
    # @param options [Hash] optional, set if stop_when_match or not.
    # @param block [Block] block code to continue operating on the matching nodes.
    def within_node(rules, options = nil, &block)
      options ||= { stop_when_match: false }
      Rewriter::WithinScope.new(self, rules, options, &block).process
    end

    alias with_node within_node

    # Parse within_direct_node dsl, it creates a [Synvert::Core::Rewriter::WithinScope] to find direct matching ast nodes,
    # then continue operating on each matching ast node.
    #
    # @param rules [Hash] rules to find mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def within_direct_node(rules, &block)
      Rewriter::WithinScope.new(self, rules, { direct: true }, &block).process
    end

    alias with_direct_node within_direct_node

    # Parse goto_node dsl, it creates a [Synvert::Core::Rewriter::GotoScope] to go to a child node,
    # then continue operating on the child node.
    #
    # @param child_node_name [Symbol|String] the name of the child nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def goto_node(child_node_name, &block)
      Rewriter::GotoScope.new(self, child_node_name, &block).process
    end

    # Parse if_exist_node dsl, it creates a [Synvert::Core::Rewriter::IfExistCondition] to check
    # if matching nodes exist in the child nodes, if so, then continue operating on each matching ast node.
    #
    # @param rules [Hash] rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def if_exist_node(rules, &block)
      Rewriter::IfExistCondition.new(self, rules, &block).process
    end

    # Parse unless_exist_node dsl, it creates a [Synvert::Core::Rewriter::UnlessExistCondition] to check
    # if matching nodes doesn't exist in the child nodes, if so, then continue operating on each matching ast node.
    #
    # @param rules [Hash] rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def unless_exist_node(rules, &block)
      Rewriter::UnlessExistCondition.new(self, rules, &block).process
    end

    # Parse if_only_exist_node dsl, it creates a [Synvert::Core::Rewriter::IfOnlyExistCondition] to check
    # if current node has only one child node and the child node matches rules,
    # if so, then continue operating on each matching ast node.
    #
    # @param rules [Hash] rules to check mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def if_only_exist_node(rules, &block)
      Rewriter::IfOnlyExistCondition.new(self, rules, &block).process
    end

    # Parse append dsl, it creates a [Synvert::Core::Rewriter::AppendAction] to
    # append the code to the bottom of current node body.
    #
    # @param code [String] code need to be appended.
    def append(code)
      @actions << Rewriter::AppendAction.new(self, code).process
    end

    # Parse prepend dsl, it creates a [Synvert::Core::Rewriter::PrependAction] to
    # prepend the code to the top of current node body.
    #
    # @param code [String] code need to be prepended.
    def prepend(code)
      @actions << Rewriter::PrependAction.new(self, code).process
    end

    # Parse insert dsl, it creates a [Synvert::Core::Rewriter::InsertAction] to
    # insert the code to the top of current node body.
    #
    # @param code [String] code need to be inserted.
    # @param at [String] insert position, beginning or end, end is the default.
    def insert(code, at: 'end')
      @actions << Rewriter::InsertAction.new(self, code, at: at).process
    end

    # Parse insert_after dsl, it creates a [Synvert::Core::Rewriter::InsertAfterAction] to
    # insert the code next to the current node.
    #
    # @param code [String] code need to be inserted.
    def insert_after(node)
      @actions << Rewriter::InsertAfterAction.new(self, node).process
    end

    # Parse replace_with dsl, it creates a [Synvert::Core::Rewriter::ReplaceWithAction] to
    # replace current node with code.
    #
    # @param code [String] code need to be replaced with.
    def replace_with(code)
      @actions << Rewriter::ReplaceWithAction.new(self, code).process
    end

    # Parse replace with dsl, it creates a [Synvert::Core::Rewriter::ReplaceAction] to
    # replace child nodes with code.
    #
    # @param selectors [Array<Symbol>] selector names of child node.
    # @param with [String] code need to be replaced with.
    def replace(*selectors, with:)
      @actions << Rewriter::ReplaceAction.new(self, *selectors, with: with).process
    end

    # Parse replace_erb_stmt_with_expr dsl, it creates a [Synvert::Core::Rewriter::ReplaceErbStmtWithExprAction] to
    # replace erb stmt code to expr code.
    def replace_erb_stmt_with_expr
      @actions << Rewriter::ReplaceErbStmtWithExprAction.new(self).process
    end

    # Parse remove dsl, it creates a [Synvert::Core::Rewriter::RemoveAction] to remove current node.
    def remove
      @actions << Rewriter::RemoveAction.new(self).process
    end

    # Parse delete dsl, it creates a [Synvert::Core::Rewriter::DeleteAction] to delete child nodes.
    #
    # @param selectors [Array<Symbol>] selector names of child node.
    def delete(*selectors)
      @actions << Rewriter::DeleteAction.new(self, *selectors).process
    end

    # Parse wrap with dsl, it creates a [Synvert::Core::Rewriter::WrapAction] to
    # wrap current node with code.
    #
    # @param with [String] code need to be wrapped with.
    # @param indent [Integer] number of whitespaces.
    def wrap(with:, indent: nil)
      @actions << Rewriter::WrapAction.new(self, with: with, indent: indent).process
    end

    # Parse warn dsl, it creates a [Synvert::Core::Rewriter::Warning] to save warning message.
    #
    # @param message [String] warning message.
    def warn(message)
      @rewriter.add_warning Rewriter::Warning.new(self, message)
    end

    # Any value but nil.
    def any_value
      Rewriter::AnyValue.new
    end

    private

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
