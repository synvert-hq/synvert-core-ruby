# frozen_string_literal: true

module Synvert::Core::NodeQuery
  autoload :Compiler, 'synvert/core/node_query/compiler'
  autoload :Lexer, 'synvert/core/node_query/lexer.rex'
  autoload :Parser, 'synvert/core/node_query/parser.racc'
end
