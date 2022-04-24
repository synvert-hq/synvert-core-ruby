# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Identifier
    include Comparable

    def initialize(value:)
      @value = value
    end

    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      elsif node.is_a?(::Array)
        node.map { |n| actual_value(n) }
      else
        node.to_s
      end
    end

    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      @value
    end
  end
end