# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # Nil represents a ruby nil value.
  class Nil
    include Comparable

    # Initialize a Nil.
    # @param value [nil] the nil value
    def initialize(value:)
      @value = value
    end

    # Get valid operators.
    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      'nil'
    end
  end
end