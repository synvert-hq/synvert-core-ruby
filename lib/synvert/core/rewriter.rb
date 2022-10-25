# frozen_string_literal: true

require 'fileutils'

module Synvert::Core
  # Rewriter is the top level namespace in a snippet.
  #
  # One Rewriter checks if the depndency version matches, and it can contain one or many {Synvert::Core::Rewriter::Instance},
  # which define the behavior what files and what codes to detect and rewrite to what code.
  class Rewriter
    DEFAULT_OPTIONS = { run_instance: true, write_to_file: true }.freeze

    autoload :ReplaceErbStmtWithExprAction, 'synvert/core/rewriter/action/replace_erb_stmt_with_expr_action'

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
      def fetch(group, name)
        group = group.to_s
        name = name.to_s
        rewriters.dig(group, name)
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
    # @!attribute [r] test_results
    #   @return [Array<Object>] the test results
    # @!attribute [rw] options
    #   @return [Hash] the rewriter options
    attr_reader :group, :name, :sub_snippets, :helpers, :warnings, :affected_files, :ruby_version, :gem_spec, :test_results
    attr_accessor :options

    # Initialize a Rewriter.
    # When a rewriter is initialized, it is already registered.
    #
    # @param group [String] group of the rewriter.
    # @param name [String] name of the rewriter.
    # @yield defines the behaviors of the rewriter, block code won't be called when initialization.
    def initialize(group, name, &block)
      @group = group
      @name = name
      @block = block
      @helpers = []
      @sub_snippets = []
      @warnings = []
      @affected_files = Set.new
      @redo_until_no_change = false
      @options = DEFAULT_OPTIONS.dup
      @test_results = []
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
      @options[:run_instance] = false
      process
    end

    def test
      @options[:write_to_file] = false
      @affected_files = Set.new
      instance_eval(&@block)

      if !@affected_files.empty? && @redo_until_no_change # redo
        test
      end
      @test_results
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

    # Configure the rewriter
    # @example
    #   configure({ strategy: 'allow_insert_at_same_position' })
    # @param options [Hash]
    # @option strategy [String] allow_insert_at_same_position
    def configure(options)
      if options[:strategy]
        @options[:strategy] = options[:strategy]
      end
    end

    # It sets description of the rewrite or get description.
    # @example
    #   Synvert::Rewriter.new 'rspec', 'use_new_syntax' do
    #     description 'It converts rspec code to new syntax, it calls all rspec sub snippets.'
    #   end
    # @param description [String] rewriter description.
    # @return rewriter description.
    def description(description = nil)
      if description
        @description = description
      else
        @description
      end
    end

    # Parse +if_ruby+ dsl, it checks if ruby version is greater than or equal to the specified ruby version.
    # @example
    #   Synvert::Rewriter.new 'ruby', 'new_safe_navigation_operator' do
    #     if_ruby '2.3.0'
    #   end
    # @param version [String] specified ruby version.
    def if_ruby(version)
      @ruby_version = Rewriter::RubyVersion.new(version)
    end

    # Parse +if_gem+ dsl, it compares version of the specified gem.
    # @example
    #   Synvert::Rewriter.new 'rails', 'upgrade_5_2_to_6_0' do
    #     if_gem 'rails', '>= 6.0'
    #   end
    # @param name [String] gem name.
    # @param version [String] equal, less than or greater than specified version, e.g. '>= 2.0.0',
    def if_gem(name, version)
      @gem_spec = Rewriter::GemSpec.new(name, version)
    end

    # Parse +within_files+ dsl, it finds specified files.
    # It creates a {Synvert::Core::Rewriter::Instance} to rewrite code.
    # @example
    #   Synvert::Rewriter.new 'rspec', 'be_close_to_be_within' do
    #     within_files '**/*.rb' do
    #     end
    #   end
    # @param file_patterns [String|Array<String>] string pattern or list of string pattern to find files, e.g. ['spec/**/*_spec.rb']
    # @param block [Block] the block to rewrite code in the matching files.
    def within_files(file_patterns, &block)
      return unless @options[:run_instance]

      return if @ruby_version && !@ruby_version.match?
      return if @gem_spec && !@gem_spec.match?

      instance = Rewriter::Instance.new(self, Array(file_patterns), &block)
      if @options[:write_to_file]
        instance.process
      else
        results = instance.test
        merge_test_results(results)
      end
    end

    # Parse +within_file+ dsl, it finds a specifiled file.
    alias within_file within_files

    # Parses +add_file+ dsl, it adds a new file.
    # @example
    #   Synvert::Rewriter.new 'rails', 'add_application_record' do
    #     add_file 'app/models/application_record.rb', <<~EOS
    #       class ApplicationRecord < ActiveRecord::Base
    #         self.abstract_class = true
    #       end
    #     EOS
    #   end
    # @param filename [String] file name of newly created file.
    # @param content [String] file body of newly created file.
    def add_file(filename, content)
      return unless @options[:run_instance]

      filepath = File.join(Configuration.root_path, filename)
      if File.exist?(filepath)
        puts "File #{filepath} already exists."
        return
      end

      FileUtils.mkdir_p File.dirname(filepath)
      File.write(filepath, content)
    end

    # Parses +remove_file+ dsl, it removes a file.
    # @example
    #   Synvert::Rewriter.new 'rails', 'upgrade_4_0_to_4_1' do
    #     remove_file 'config/initializers/secret_token.rb'
    #   end
    # @param filename [String] file name.
    def remove_file(filename)
      return unless @options[:run_instance]

      file_path = File.join(Configuration.root_path, filename)
      File.delete(file_path) if File.exist?(file_path)
    end

    # Parse +add_snippet+ dsl, it calls anther rewriter.
    # @example
    #   Synvert::Rewriter.new 'minitest', 'better_syntax' do
    #     add_snippet 'minitest', 'assert_empty'
    #     add_snippet 'minitest', 'assert_equal_arguments_order'
    #     add_snippet 'minitest/assert_instance_of'
    #     add_snippet 'minitest/assert_kind_of'
    #     add_snippet '/Users/flyerhzm/.synvert-ruby/lib/minitest/assert_match.rb'
    #     add_snippet '/Users/flyerhzm/.synvert-ruby/lib/minitest/assert_nil.rb'
    #     add_snippet 'https://github.com/xinminlabs/synvert-snippets-ruby/blob/main/lib/minitest/assert_silent.rb'
    #     add_snippet 'https://github.com/xinminlabs/synvert-snippets-ruby/blob/main/lib/minitest/assert_truthy.rb'
    #   end
    # @param group [String] group of another rewriter, if there's no name parameter, the group can be http url, file path or snippet name.
    # @param name [String] name of another rewriter.
    def add_snippet(group, name = nil)
      rewriter =
        if name
          Rewriter.fetch(group, name) || Utils.eval_snippet([group, name].join('/'))
        else
          Utils.eval_snippet(group)
        end
      return unless rewriter && rewriter.is_a?(Rewriter)

      rewriter.options = @options
      if !rewriter.options[:write_to_file]
        results = rewriter.test
        merge_test_results(results)
      elsif rewriter.options[:run_instance]
        rewriter.process
      else
        rewriter.process_with_sandbox
      end
      @sub_snippets << rewriter
    end

    # Parse +helper_method+ dsl, it defines helper method for {Synvert::Core::Rewriter::Instance}.
    # @example
    #   Synvert::Rewriter.new 'rails', 'convert_active_record_dirty_5_0_to_5_1' do
    #     helper_method :find_callbacks_and_convert do |callback_names, callback_changes|
    #       # do anything, method find_callbacks_and_convert can be reused later.
    #     end
    #     within_files Synvert::RAILS_MODEL_FILES + Synvert::RAILS_OBSERVER_FILES do
    #       find_callbacks_and_convert(before_callback_names, before_callback_changes)
    #       find_callbacks_and_convert(after_callback_names, after_callback_changes)
    #     end
    #   end
    # @param name [String] helper method name.
    # @yield helper method block.
    def helper_method(name, &block)
      @helpers << { name: name, block: block }
    end

    # Parse +todo+ dsl, it sets todo of the rewriter.
    # Or get todo.
    # @example
    #   Synvert::Rewriter.new 'rails', 'upgrade_3_2_to_4_0' do
    #     todo <<~EOS
    #       1. Rails 4.0 no longer supports loading plugins from vendor/plugins. You must replace any plugins by extracting them to gems and adding them to your Gemfile. If you choose not to make them gems, you can move them into, say, lib/my_plugin/* and add an appropriate initializer in config/initializers/my_plugin.rb.
    #       2.  Make the following changes to your Gemfile.
    #           gem 'sass-rails', '~> 4.0.0'
    #           gem 'coffee-rails', '~> 4.0.0'
    #           gem 'uglifier', '>= 1.3.0'
    #     EOS
    #   end
    # @param todo [String] rewriter todo.
    # @return [String] rewriter todo.
    def todo(todo = nil)
      if todo
        @todo = todo
      else
        @todo
      end
    end

    # Rerun the snippet until no change.
    # @example
    #   Synvert::Rewriter.new 'ruby', 'nested_class_definition' do
    #     redo_until_no_change
    #   end
    def redo_until_no_change
      @redo_until_no_change = true
    end

    private

    def merge_test_results(results)
      @test_results += results.select { |result| result.affected? }
    end
  end
end
