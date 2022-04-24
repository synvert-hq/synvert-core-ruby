# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class AttributeList
    def initialize(attribute:, attribute_list: nil)
      @attribute = attribute
      @attribute_list = attribute_list
    end

    def match?(node, operator = :==)
      @attribute.match?(node, operator) && (!@attribute_list || @attribute_list.match?(node, operator))
    end

    def to_s
      "[#{@attribute}]#{@attribute_list}"
    end
  end
end