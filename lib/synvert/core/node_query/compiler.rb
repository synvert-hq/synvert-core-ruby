# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  autoload :Array, 'synvert/core/node_query/compiler/array'
  autoload :AttributeList, 'synvert/core/node_query/compiler/attribute_list'
  autoload :AttributeValue, 'synvert/core/node_query/compiler/attribute_value'
  autoload :Attribute, 'synvert/core/node_query/compiler/attribute'
  autoload :Boolean, 'synvert/core/node_query/compiler/boolean'
  autoload :Comparable, 'synvert/core/node_query/compiler/comparable'
  autoload :Expression, 'synvert/core/node_query/compiler/expression'
  autoload :Float, 'synvert/core/node_query/compiler/float'
  autoload :Identifier, 'synvert/core/node_query/compiler/identifier'
  autoload :Integer, 'synvert/core/node_query/compiler/integer'
  autoload :InvalidOperatorError, 'synvert/core/node_query/compiler/invalid_operator_error'
  autoload :Nil, 'synvert/core/node_query/compiler/nil'
  autoload :Regexp, 'synvert/core/node_query/compiler/regexp'
  autoload :Selector, 'synvert/core/node_query/compiler/selector'
  autoload :String, 'synvert/core/node_query/compiler/string'
  autoload :Symbol, 'synvert/core/node_query/compiler/symbol'
end