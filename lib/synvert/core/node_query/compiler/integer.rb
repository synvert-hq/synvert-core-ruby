# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Integer represents a ruby integer value.
  class Integer
    include Comparable

    # Initialize a Integer.
    # @param value [Integer] the integer value
    def initialize(value:)
      @value = value
    end

    # Get valid operators.
    def valid_operators
      NUMBER_VALID_OPERATORS
    end

    def to_s
      @value.to_s
    end
  end
end
