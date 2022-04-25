# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Boolean represents a ruby boolean value.
  class Boolean
    include Comparable

    # Initialize a Boolean.
    # @param value [Boolean] the boolean value
    def initialize(value:)
      @value = value
    end

    # Get valid operators.
    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      @value.to_s
    end
  end
end
