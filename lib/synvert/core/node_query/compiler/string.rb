# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # String represents a ruby string value.
  class String
    include Comparable

    # Initialize a String.
    # @param value [String] the string value
    def initialize(value:)
      @value = value
    end

    # Get valid operators.
    def valid_operators
      STRING_VALID_OPERATORS
    end

    def to_s
      "\"#{@value}\""
    end
  end
end
