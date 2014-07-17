# encoding: utf-8

module Synvert::Core
  # Rewriter is the top level namespace in a snippet.
  #
  # One Rewriter can contain one or many [Synvert::Core::Rewriter::Instance],
  # which define the behavior what files and what codes to detect and rewrite to what code.
  #
  #   Synvert::Rewriter.new 'factory_girl_short_syntax', 'use FactoryGirl short syntax' do
  #     if_gem 'factory_girl', {gte: '2.0.0'}
  #
  #     within_files 'spec/**/*.rb' do
  #       with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
  #         replace_with "create({{arguments}})"
  #       end
  #     end
  #   end
  class Rewriter
    autoload :Action, 'synvert/core/rewriter/action'
    autoload :AppendAction, 'synvert/core/rewriter/action'
    autoload :InsertAction, 'synvert/core/rewriter/action'
    autoload :InsertAfterAction, 'synvert/core/rewriter/action'
    autoload :ReplaceWithAction, 'synvert/core/rewriter/action'
    autoload :ReplaceErbStmtWithExprAction, 'synvert/core/rewriter/action'
    autoload :RemoveAction, 'synvert/core/rewriter/action'

    autoload :Warning, 'synvert/core/rewriter/warning'

    autoload :Instance, 'synvert/core/rewriter/instance'

    autoload :Scope, 'synvert/core/rewriter/scope'

    autoload :Condition, 'synvert/core/rewriter/condition'
    autoload :IfExistCondition, 'synvert/core/rewriter/condition'
    autoload :UnlessExistCondition, 'synvert/core/rewriter/condition'
    autoload :IfOnlyExistCondition, 'synvert/core/rewriter/condition'

    autoload :GemSpec, 'synvert/core/rewriter/gem_spec'

    class <<self
      # Register a rewriter with its name.
      #
      # @param name [String] the unique rewriter name.
      # @param rewriter [Synvert::Core::Rewriter] the rewriter to register.
      def register(name, rewriter)
        @rewriters ||= {}
        @rewriters[name] = rewriter
      end

      # Fetch a rewriter by name.
      #
      # @param name [String] rewrtier name.
      # @return [Synvert::Core::Rewriter] the matching rewriter.
      def fetch(name)
        @rewriters[name]
      end

      # Get a registered rewriter by name and process that rewriter.
      #
      # @param name [String] the rewriter name.
      # @return [Synvert::Core::Rewriter] the registered rewriter.
      # @raise [Synvert::Core::RewriterNotFound] if the registered rewriter is not found.
      def call(name)
        if (rewriter = @rewriters[name])
          rewriter.process
          rewriter
        else
          raise RewriterNotFound.new "Rewriter #{name} not found"
        end
      end

      # Get all available rewriters
      #
      # @return [Array<Synvert::Core::Rewriter>]
      def availables
        @rewriters ? @rewriters.values : []
      end

      # Clear all registered rewriters.
      def clear
        @rewriters.clear
      end
    end

    # @!attribute [r] name
    #   @return [String] the unique name of rewriter
    # @!attribute [r] sub_snippets
    #   @return [Array<Synvert::Core::Rewriter>] all rewriters this rewiter calls.
    # @!attribute [r] helper
    #   @return [Array] helper methods.
    # @!attribute [r] warnings
    #   @return [Array<Synvert::Core::Rewriter::Warning>] warning messages.
    attr_reader :name, :sub_snippets, :helpers, :warnings

    # Initialize a rewriter.
    # When a rewriter is initialized, it is also registered.
    #
    # @param name [String] name of the rewriter.
    # @param block [Block] a block defines the behaviors of the rewriter, block code won't be called when initialization.
    # @return [Synvert::Core::Rewriter]
    def initialize(name, &block)
      @name = name.to_s
      @block = block
      @helpers = []
      @sub_snippets = []
      @warnings = []
      self.class.register(@name, self)
    end

    # Process the rewriter.
    # It will call the block.
    def process
      self.instance_eval &@block
    end

    # Process rewriter with sandbox mode.
    # It will call the block but doesn't change any file.
    def process_with_sandbox
      @sandbox = true
      self.process
      @sandbox = false
    end

    # Add a warning.
    #
    # @param warning [Synvert::Core::Rewriter::Warning]
    def add_warning(warning)
      @warnings << warning
    end

    #######
    # DSL #
    #######

    # Parse description dsl, it sets description of the rewrite.
    # Or get description.
    #
    # @param description [String] rewriter description.
    # @return rewriter description.
    def description(description=nil)
      if description
        @description = description
      else
        @description
      end
    end

    # Parse if_gem dsl, it compares version of the specified gem.
    #
    # @param name [String] gem name.
    # @param comparator [Hash] equal, less than or greater than specified version, e.g. {gte: '2.0.0'},
    #   key can be eq, lt, gt, lte, gte or ne.
    def if_gem(name, comparator)
      @gem_spec = Rewriter::GemSpec.new(name, comparator)
    end

    # Parse within_files dsl, it finds specified files.
    # It creates a [Synvert::Core::Rewriter::Instance] to rewrite code.
    #
    # @param file_pattern [String] pattern to find files, e.g. spec/**/*_spec.rb
    # @param block [Block] the block to rewrite code in the matching files.
    def within_files(file_pattern, &block)
      return if @sandbox

      if !@gem_spec || @gem_spec.match?
        Rewriter::Instance.new(self, file_pattern, &block).process
      end
    end

    # Parse within_file dsl, it finds a specifiled file.
    alias within_file within_files

    # Parses add_file dsl, it adds a new file.
    #
    # @param filename [String] file name of newly created file.
    # @param content [String] file body of newly created file.
    def add_file(filename, content)
      return if @sandbox

      File.open File.join(Configuration.instance.get(:path), filename), 'w' do |file|
        file.write content
      end
    end

    # Parses remove_file dsl, it removes a file.
    #
    # @param filename [String] file name.
    def remove_file(filename)
      return if @sandbox

      file_path = File.join(Configuration.instance.get(:path), filename)
      File.delete(file_path) if File.exist?(file_path)
    end

    # Parse add_snippet dsl, it calls anther rewriter.
    #
    # @param name [String] name of another rewriter.
    def add_snippet(name)
      @sub_snippets << self.class.call(name.to_s)
    end

    # Parse helper_method dsl, it defines helper method for [Synvert::Core::Rewriter::Instance].
    #
    # @param name [String] helper method name.
    # @param block [Block] helper method block.
    def helper_method(name, &block)
      @helpers << {name: name, block: block}
    end

    # Parse todo dsl, it sets todo of the rewriter.
    # Or get todo.
    #
    # @param todo_list [String] rewriter todo.
    # @return [String] rewriter todo.
    def todo(todo=nil)
      if todo
        @todo = todo
      else
        @todo
      end
    end
  end
end
