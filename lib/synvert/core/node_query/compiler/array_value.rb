# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class ArrayValue
    include Comparable

    def initialize(value: nil, rest: nil)
      @value = value
      @rest = rest
    end

    def expected_value
      expected = []
      expected.push(@value) if @value
      expected += @rest.expected_value if @rest
      expected
    end

    def valid_operators
      ARRAY_VALID_OPERATORS
    end

    def to_s
      [@value, @rest].compact.join(', ')
    end
  end
end