# frozen_string_literal: true

module Synvert::Core::NodeQuery::Compiler
  autoload :InvalidOperatorError, 'synvert/core/node_query/compiler/invalid_operator_error'
  autoload :ParseError, 'synvert/core/node_query/compiler/parse_error'

  autoload :Comparable, 'synvert/core/node_query/compiler/comparable'

  autoload :Expression, 'synvert/core/node_query/compiler/expression'
  autoload :Selector, 'synvert/core/node_query/compiler/selector'
  autoload :BasicSelector, 'synvert/core/node_query/compiler/basic_selector'
  autoload :AttributeList, 'synvert/core/node_query/compiler/attribute_list'
  autoload :Attribute, 'synvert/core/node_query/compiler/attribute'

  autoload :Array, 'synvert/core/node_query/compiler/array'
  autoload :Boolean, 'synvert/core/node_query/compiler/boolean'
  autoload :DynamicAttribute, 'synvert/core/node_query/compiler/dynamic_attribute'
  autoload :Float, 'synvert/core/node_query/compiler/float'
  autoload :Identifier, 'synvert/core/node_query/compiler/identifier'
  autoload :Integer, 'synvert/core/node_query/compiler/integer'
  autoload :Nil, 'synvert/core/node_query/compiler/nil'
  autoload :Regexp, 'synvert/core/node_query/compiler/regexp'
  autoload :String, 'synvert/core/node_query/compiler/string'
  autoload :Symbol, 'synvert/core/node_query/compiler/symbol'
end
