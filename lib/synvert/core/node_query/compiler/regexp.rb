# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Regexp
    include Comparable

    def initialize(value:)
      @value = value
    end

    def match?(node, operator)
      if node.is_a?(::Parser::AST::Node)
        @value.match(node.to_source)
      else
        @value.match(node.to_s)
      end
    end

    def valid_operators
      REGEXP_VALID_OPERATORS
    end

    def to_s
      @value.to_s
    end
  end
end