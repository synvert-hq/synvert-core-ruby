# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Symbol represents a ruby symbol value.
  class Symbol
    include Comparable

    # Initliaze a Symobol.
    # @param value [Symbol] the symbol value
    def initialize(value:)
      @value = value
    end

    # Get valid operators.
    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      ":#{@value}"
    end
  end
end
