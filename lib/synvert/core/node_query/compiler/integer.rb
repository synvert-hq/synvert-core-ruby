# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Integer
    include Comparable

    def initialize(value:)
      @value = value
    end

    def valid_operators
      NUMBER_VALID_OPERATORS
    end

    def to_s
      @value.to_s
    end
  end
end