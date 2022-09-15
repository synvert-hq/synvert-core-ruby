# frozen_string_literal: true

module Synvert::Core
  # Condition checks if rules matches.
  class Rewriter::Condition
    # Initialize a Condition.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param rules [Hash]
    # @yield run when condition matches
    def initialize(instance, rules, &block)
      @instance = instance
      @node_query = NodeQuery.new(rules)
      @block = block
    end

    # If condition matches, run the block code.
    def process
      @instance.instance_eval(&@block) if match?
    end

    protected

    # Check if condition matches
    #
    # @abstract
    def match?
      raise NotImplementedError, 'must be implemented by subclasses'
    end

    def target_node
      @instance.current_node
    end
  end
end
