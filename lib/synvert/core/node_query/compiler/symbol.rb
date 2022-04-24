# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Symbol node represents a symbol value.
  class Symbol
    include Comparable

    def initialize(value:)
      @value = value
    end

    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      ":#{@value}"
    end
  end
end