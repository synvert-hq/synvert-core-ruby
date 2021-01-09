# encoding: utf-8
# frozen_string_literal: true

module Synvert::Core
  # Instance is an execution unit, it finds specified ast nodes,
  # checks if the nodes match some conditions, then add, replace or remove code.
  #
  # One instance can contains one or many [Synvert::Core::Rewriter::Scope] and [Synvert::Rewriter::Condition].
  class Rewriter::Instance
    include Rewriter::Helper

    class <<self
      # Cached file source.
      #
      # @param file_path [String] file path
      # @return [String] file source
      def file_source(file_path)
        @file_source ||= {}
        @file_source[file_path] ||=
          begin
            source = File.read(file_path)
            source = Engine::ERB.encode(source) if file_path =~ /\.erb$/
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
        source = Engine::ERB.decode(source) if file_path =~ /\.erb/
        File.write file_path, source.gsub(/ +\n/, "\n")
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

    DEFAULT_OPTIONS = { sort_by: 'begin_pos' }

    # Initialize an instance.
    #
    # @param rewriter [Synvert::Core::Rewriter]
    # @param file_pattern [String] pattern to find files, e.g. spec/**/*_spec.rb
    # @param options [Hash] instance options, it includes :sort_by.
    # @param block [Block] block code to find nodes, match conditions and rewrite code.
    # @return [Synvert::Core::Rewriter::Instance]
    def initialize(rewriter, file_pattern, options={}, &block)
      @rewriter = rewriter
      @actions = []
      @file_pattern = file_pattern
      @options = DEFAULT_OPTIONS.merge(options)
      @block = block
      rewriter.helpers.each { |helper| self.singleton_class.send(:define_method, helper[:name], &helper[:block]) }
    end

    # Process the instance.
    # It finds all files, for each file, it executes the block code, gets all rewrite actions,
    # and rewrite source code back to original file.
    def process
      file_pattern = File.join(Configuration.instance.get(:path), @file_pattern)
      Dir.glob(file_pattern).each do |file_path|
        next if Configuration.instance.get(:skip_files).include? file_path
        begin
          conflict_actions = []
          source = self.class.file_source(file_path)
          ast = self.class.file_ast(file_path)

          @current_file = file_path

          self.process_with_node ast do
            begin
              instance_eval &@block
            rescue NoMethodError
              puts @current_node.debug_info
              raise
            end
          end

          if @actions.length > 0
            @actions.sort_by! { |action| action.send(@options[:sort_by]) }
            conflict_actions = get_conflict_actions
            @actions.reverse.each do |action|
              source[action.begin_pos...action.end_pos] = action.rewritten_code
              source = remove_code_or_whole_line(source, action.line)
            end
            @actions = []

            self.class.write_file(file_path, source)
          end
        rescue Parser::SyntaxError
          puts "[Warn] file #{file_path} was not parsed correctly."
          # do nothing, iterate next file
        end while !conflict_actions.empty?
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
    # @param node [Parser::AST::Node] node set to current_node
    # @yield process
    def process_with_other_node(node)
      original_node = self.current_node
      self.current_node = node
      yield
      self.current_node = original_node
    end

    #######
    # DSL #
    #######

    # Parse within_node dsl, it creates a [Synvert::Core::Rewriter::WithinScope] to find matching ast nodes,
    # then continue operating on each matching ast node.
    #
    # @param rules [Hash] rules to find mathing ast nodes.
    # @param block [Block] block code to continue operating on the matching nodes.
    def within_node(rules, &block)
      Rewriter::WithinScope.new(self, rules, &block).process
    end

    # Parse goto_node dsl, it creates a [Synvert::Core::Rewriter::GotoScope] to go to a child node,
    # then continue operating on the child node.
    #
    # @param child_node_name [String] the name of the child node.
    # @param block [Block] block code to continue operating on the matching nodes.
    def goto_node(child_node_name, &block)
      Rewriter::GotoScope.new(self, child_node_name, &block).process
    end

    alias_method :with_node, :within_node

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
    # @param options [Hash] action options.
    def append(code, options={})
      @actions << Rewriter::AppendAction.new(self, code, options)
    end

    # Parse insert dsl, it creates a [Synvert::Core::Rewriter::InsertAction] to
    # insert the code to the top of current node body.
    #
    # @param code [String] code need to be inserted.
    # @param options [Hash] action options.
    def insert(code, options={})
      @actions << Rewriter::InsertAction.new(self, code, options)
    end

    # Parse insert_after dsl, it creates a [Synvert::Core::Rewriter::InsertAfterAction] to
    # insert the code next to the current node.
    #
    # @param code [String] code need to be inserted.
    # @param options [Hash] action options.
    def insert_after(node, options={})
      @actions << Rewriter::InsertAfterAction.new(self, node, options)
    end

    # Parse replace_with dsl, it creates a [Synvert::Core::Rewriter::ReplaceWithAction] to
    # replace current node with code.
    #
    # @param code [String] code need to be replaced with.
    # @param options [Hash] action options.
    def replace_with(code, options={})
      @actions << Rewriter::ReplaceWithAction.new(self, code, options)
    end

    # Parse replace_erb_stmt_with_expr dsl, it creates a [Synvert::Core::Rewriter::ReplaceErbStmtWithExprAction] to
    # replace erb stmt code to expr code.
    def replace_erb_stmt_with_expr
      @actions << Rewriter::ReplaceErbStmtWithExprAction.new(self)
    end

    # Parse remove dsl, it creates a [Synvert::Core::Rewriter::RemoveAction] to current node.
    def remove
      @actions << Rewriter::RemoveAction.new(self)
    end

    # Parse warn dsl, it creates a [Synvert::Core::Rewriter::Warning] to save warning message.
    #
    # @param message [String] warning message.
    def warn(message)
      @rewriter.add_warning Rewriter::Warning.new(self, message)
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
        if begin_pos <= @actions[j].end_pos
          conflict_actions << @actions.delete_at(j)
        else
          i = j
          begin_pos = @actions[i].begin_pos
        end
        j -= 1
      end
      conflict_actions
    end

    # It checks if code is removed and that line is empty.
    #
    # @param source [String] source code of file
    # @param line [String] the line number
    def remove_code_or_whole_line(source, line)
      newline_at_end_of_line = source[-1] == "\n"
      source_arr = source.split("\n")
      if source_arr[line - 1] && source_arr[line - 1].strip.empty?
        source_arr.delete_at(line - 1)
        if source_arr[line - 2] && source_arr[line - 2].strip.empty? && source_arr[line - 1] && source_arr[line - 1].strip.empty?
          source_arr.delete_at(line - 1)
        end
        source_arr.join("\n") + (newline_at_end_of_line ? "\n" : '')
      else
        source
      end
    end
  end
end
