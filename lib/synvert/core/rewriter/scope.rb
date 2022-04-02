# frozen_string_literal: true

module Synvert::Core
  # Scope finds out nodes which match rules.
  class Rewriter::Scope
    # Initialize a Scope
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @yield run on a scope
    def initialize(instance, &block)
      @instance = instance
      @block = block
    end
  end
end
