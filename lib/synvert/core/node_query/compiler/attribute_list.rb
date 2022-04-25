# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  # AttributeList contains one or more {Synvert::Core::NodeQuery::Compiler::Attribute}.
  class AttributeList
    # Initialize a AttributeList.
    # @param attribute [Synvert::Core::NodeQuery::Compiler::Attribute] the attribute
    # @param rest [Synvert::Core::NodeQuery::Compiler::AttributeList] the rest attribute list
    def initialize(attribute:, rest: nil)
      @attribute = attribute
      @rest = rest
    end

    # Check if the node matches the attribute list.
    # @return [Boolean]
    def match?(node)
      @attribute.match?(node) && (!@rest || @rest.match?(node))
    end

    def to_s
      "[#{@attribute}]#{@rest}"
    end
  end
end
