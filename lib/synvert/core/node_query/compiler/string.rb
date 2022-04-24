# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class String
    include Comparable

    def initialize(value:)
      @value = value
    end

    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      else
        node.to_s
      end
    end

    def to_s
      "\"#{@value}\""
    end
  end
end