# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class DynamicAttribute
    include Comparable

    attr_accessor :base_node

    def initialize(value:)
      @value = value
    end

    def actual_value(node)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      else
        node
      end
    end

    def expected_value
      node = base_node.child_node_by_name(@value)
      if node.is_a?(::Parser::AST::Node)
        node.to_source
      else
        node
      end
    end

    def valid_operators
      SIMPLE_VALID_OPERATORS
    end

    def to_s
      "{{#{@value}}}"
    end
  end
end