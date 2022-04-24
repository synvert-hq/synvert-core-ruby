# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Boolean
    include Comparable

    def initialize(value:)
      @value = value
    end

    def to_s
      @value.to_s
    end

    def valid_operators
      SIMPLE_VALID_OPERATORS
    end
  end
end