# frozen_string_literal: true

require 'fileutils'

module Synvert::Core
  # Rewriter is the top level namespace in a snippet.
  #
  # One Rewriter can contain one or many [Synvert::Core::Rewriter::Instance],
  # which define the behavior what files and what codes to detect and rewrite to what code.
  #
  #   Synvert::Rewriter.new 'factory_girl_short_syntax', 'use FactoryGirl short syntax' do
  #     if_gem 'factory_girl', '>= 2.0.0'
  #
  #     within_files 'spec/**/*.rb' do
  #       with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
  #         replace_with "create({{arguments}})"
  #       end
  #     end
  #   end
  class Rewriter
    autoload :Action, 'synvert/core/rewriter/action'
    autoload :AppendAction, 'synvert/core/rewriter/action/append_action'
    autoload :DeleteAction, 'synvert/core/rewriter/action/delete_action'
    autoload :InsertAction, 'synvert/core/rewriter/action/insert_action'
    autoload :InsertAfterAction, 'synvert/core/rewriter/action/insert_after_action'
    autoload :RemoveAction, 'synvert/core/rewriter/action/remove_action'
    autoload :PrependAction, 'synvert/core/rewriter/action/prepend_action'
    autoload :ReplaceAction, 'synvert/core/rewriter/action/replace_action'
    autoload :ReplaceErbStmtWithExprAction, 'synvert/core/rewriter/action/replace_erb_stmt_with_expr_action'
    autoload :ReplaceWithAction, 'synvert/core/rewriter/action/replace_with_action'
    autoload :WrapAction, 'synvert/core/rewriter/action/wrap_action'

    autoload :Warning, 'synvert/core/rewriter/warning'

    autoload :Instance, 'synvert/core/rewriter/instance'

    autoload :Scope, 'synvert/core/rewriter/scope'
    autoload :WithinScope, 'synvert/core/rewriter/scope/within_scope'
    autoload :GotoScope, 'synvert/core/rewriter/scope/goto_scope'

    autoload :Condition, 'synvert/core/rewriter/condition'
    autoload :IfExistCondition, 'synvert/core/rewriter/condition/if_exist_condition'
    autoload :UnlessExistCondition, 'synvert/core/rewriter/condition/unless_exist_condition'
    autoload :IfOnlyExistCondition, 'synvert/core/rewriter/condition/if_only_exist_condition'

    autoload :Helper, 'synvert/core/rewriter/helper'

    autoload :RubyVersion, 'synvert/core/rewriter/ruby_version'
    autoload :GemSpec, 'synvert/core/rewriter/gem_spec'

    autoload :AnyValue, 'synvert/core/rewriter/any_value'

    class << self
      # Execute the temporary rewriter without group and name.
      #
      # @param block [Block] a block defines the behaviors of the rewriter.
      def execute(&block)
        rewriter = Rewriter.new('', '', &block)
        rewriter.process
        rewriter
      end

      # Register a rewriter with its group and name.
      #
      # @param group [String] the rewriter group.
      # @param name [String] the unique rewriter name.
      # @param rewriter [Synvert::Core::Rewriter] the rewriter to register.
      def register(group, name, rewriter)
        group = group.to_s
        name = name.to_s
        rewriters[group] ||= {}
        rewriters[group][name] = rewriter
      end

      # Fetch a rewriter by group and name.
      #
      # @param group [String] rewrtier group.
      # @param name [String] rewrtier name.
      # @return [Synvert::Core::Rewriter] the matching rewriter.
      # @raise [Synvert::Core::RewriterNotFound] if the registered rewriter is not found.
      def fetch(group, name)
        group = group.to_s
        name = name.to_s
        rewriter = rewriters.dig(group, name)
        raise RewriterNotFound, "Rewriter #{group} #{name} not found" unless rewriter

        rewriter
      end

      # Get a registered rewriter by group and name, then process that rewriter.
      #
      # @param group [String] the rewriter group.
      # @param name [String] the rewriter name.
      # @param sandbox [Boolean] if run in sandbox mode, default is false.
      # @return [Synvert::Core::Rewriter] the registered rewriter.
      # @raise [Synvert::Core::RewriterNotFound] if the registered rewriter is not found.
      def call(group, name, sandbox = false)
        rewriter = fetch(group, name)
        if sandbox
          rewriter.process_with_sandbox
        else
          rewriter.process
        end
        rewriter
      end

      # Get all available rewriters
      #
      # @return [Hash<String, Hash<String, Rewriter>>]
      def availables
        rewriters
      end

      # Clear all registered rewriters.
      def clear
        rewriters.clear
      end

      private

      def rewriters
        @rewriters ||= {}
      end
    end

    # @!attribute [r] group
    #   @return [String] the group of rewriter
    # @!attribute [r] name
    #   @return [String] the unique name of rewriter
    # @!attribute [r] sub_snippets
    #   @return [Array<Synvert::Core::Rewriter>] all rewriters this rewiter calls.
    # @!attribute [r] helper
    #   @return [Array] helper methods.
    # @!attribute [r] warnings
    #   @return [Array<Synvert::Core::Rewriter::Warning>] warning messages.
    # @!attribute [r] affected_files
    #   @return [Set] affected fileds
    # @!attribute [r] ruby_version
    #   @return [Rewriter::RubyVersion] the ruby version
    # @!attribute [r] gem_spec
    #   @return [Rewriter::GemSpec] the gem spec
    attr_reader :group, :name, :sub_snippets, :helpers, :warnings, :affected_files, :ruby_version, :gem_spec

    # Initialize a rewriter.
    # When a rewriter is initialized, it is also registered.
    #
    # @param group [String] group of the rewriter.
    # @param name [String] name of the rewriter.
    # @param block [Block] a block defines the behaviors of the rewriter, block code won't be called when initialization.
    # @return [Synvert::Core::Rewriter]
    def initialize(group, name, &block)
      @group = group
      @name = name
      @block = block
      @helpers = []
      @sub_snippets = []
      @warnings = []
      @affected_files = Set.new
      @redo_until_no_change = false
      self.class.register(@group, @name, self)
    end

    # Process the rewriter.
    # It will call the block.
    def process
      @affected_files = Set.new
      instance_eval(&@block)

      process if !@affected_files.empty? && @redo_until_no_change # redo
    end

    # Process rewriter with sandbox mode.
    # It will call the block but doesn't change any file.
    def process_with_sandbox
      @sandbox = true
      begin
        process
      ensure
        @sandbox = false
      end
    end

    # Add a warning.
    #
    # @param warning [Synvert::Core::Rewriter::Warning]
    def add_warning(warning)
      @warnings << warning
    end

    # Add an affected file.
    #
    # @param file_path [String]
    def add_affected_file(file_path)
      @affected_files.add(file_path)
    end

    #######
    # DSL #
    #######

    # Parse description dsl, it sets description of the rewrite.
    # Or get description.
    #
    # @param description [String] rewriter description.
    # @return rewriter description.
    def description(description = nil)
      if description
        @description = description
      else
        @description
      end
    end

    # Parse if_ruby dsl, it checks if ruby version if greater than or equal to the specified ruby version.
    #
    # @param version, [String] specified ruby version.
    def if_ruby(version)
      @ruby_version = Rewriter::RubyVersion.new(version)
    end

    # Parse if_gem dsl, it compares version of the specified gem.
    #
    # @param name [String] gem name.
    # @param version [String] equal, less than or greater than specified version, e.g. '>= 2.0.0',
    def if_gem(name, version)
      @gem_spec = Rewriter::GemSpec.new(name, version)
    end

    # Parse within_files dsl, it finds specified files.
    # It creates a [Synvert::Core::Rewriter::Instance] to rewrite code.
    #
    # @param file_patterns [String|Array<String>] string pattern or list of string pattern to find files, e.g. ['spec/**/*_spec.rb']
    # @param block [Block] the block to rewrite code in the matching files.
    def within_files(file_patterns, &block)
      return if @sandbox

      return if @ruby_version && !@ruby_version.match?
      return if @gem_spec && !@gem_spec.match?

      Rewriter::Instance.new(self, Array(file_patterns), &block).process
    end

    # Parse within_file dsl, it finds a specifiled file.
    alias within_file within_files

    # Parses add_file dsl, it adds a new file.
    #
    # @param filename [String] file name of newly created file.
    # @param content [String] file body of newly created file.
    def add_file(filename, content)
      return if @sandbox

      filepath = File.join(Configuration.path, filename)
      if File.exist?(filepath)
        puts "File #{filepath} already exists."
        return
      end

      FileUtils.mkdir_p File.dirname(filepath)
      File.write(filepath, content)
    end

    # Parses remove_file dsl, it removes a file.
    #
    # @param filename [String] file name.
    def remove_file(filename)
      return if @sandbox

      file_path = File.join(Configuration.path, filename)
      File.delete(file_path) if File.exist?(file_path)
    end

    # Parse add_snippet dsl, it calls anther rewriter.
    #
    # @param group [String] group of another rewriter.
    # @param name [String] name of another rewriter.
    def add_snippet(group, name)
      @sub_snippets << self.class.call(group.to_s, name.to_s, @sandbox)
    end

    # Parse helper_method dsl, it defines helper method for [Synvert::Core::Rewriter::Instance].
    #
    # @param name [String] helper method name.
    # @param block [Block] helper method block.
    def helper_method(name, &block)
      @helpers << { name: name, block: block }
    end

    # Parse todo dsl, it sets todo of the rewriter.
    # Or get todo.
    #
    # @param todo_list [String] rewriter todo.
    # @return [String] rewriter todo.
    def todo(todo = nil)
      if todo
        @todo = todo
      else
        @todo
      end
    end

    # Rerun the snippet until no change.
    def redo_until_no_change
      @redo_until_no_change = true
    end
  end
end
