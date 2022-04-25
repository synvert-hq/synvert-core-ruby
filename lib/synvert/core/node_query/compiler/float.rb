# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Float represents a ruby float value.
  class Float
    include Comparable

    # Initialize a Float.
    # @param value [Float] the float value
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
