# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  class Attribute
    def initialize(key:, value:, operator: :==)
      @key = key
      @value = value
      @operator = operator
    end

    def match?(node, operator = :==)
      @value.base_node = node if @value.is_a?(AttributeValue)
      node && @value.match?(node.child_node_by_name(@key), @operator)
    end

    def to_s
      case @operator
      when :!=
        "#{@key}!=#{@value}"
      when :=~
        "#{@key}=~#{@value}"
      when :!~
        "#{@key}!~#{@value}"
      when :>
        "#{@key}>#{@value}"
      when :>=
        "#{@key}>=#{@value}"
      when :<
        "#{@key}<#{@value}"
      when :<=
        "#{@key}<=#{@value}"
      when :in
        "#{@key} in (#{@value})"
      when :not_in
        "#{@key} not in (#{@value})"
      when :includes
        "#{@key} includes #{@value}"
      else
        "#{@key}=#{@value}"
      end
    end
  end
end