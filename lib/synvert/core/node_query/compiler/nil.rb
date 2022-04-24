# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Nil
    include Comparable

    def initialize(value:)
      @value = value
    end

    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      'nil'
    end
  end
end