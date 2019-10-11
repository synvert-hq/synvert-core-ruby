# encoding: utf-8
# frozen_string_literal: true

module Synvert::Core
  # Condition checks if rules matches.
  class Rewriter::Condition
    # Initialize a condition.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param rules [Hash]
    # @param block [Block]
    # @return [Synvert::Core::Rewriter::Condition]
    def initialize(instance, rules, &block)
      @instance = instance
      @rules = rules
      @block = block
    end

    # If condition matches, run the block code.
    def process
      @instance.instance_eval &@block if match?
    end
  end
end
