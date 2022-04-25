# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Array represents a ruby array value.
  class Array
    include Comparable

    # Initialize an Array.
    # @param value the first value of the array
    # @param rest the rest value of the array
    def initialize(value: nil, rest: nil)
      @value = value
      @rest = rest
    end

    # Get the expected value.
    # @return [Array]
    def expected_value
      expected = []
      expected.push(@value) if @value
      expected += @rest.expected_value if @rest
      expected
    end

    # Get valid operators.
    def valid_operators
      ARRAY_VALID_OPERATORS
    end

    def to_s
      [@value, @rest].compact.join(', ')
    end
  end
end
