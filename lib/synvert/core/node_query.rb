# frozen_string_literal: true

module Synvert::Core::NodeQuery
  autoload :Lexer, 'synvert/core/node_query/lexer.rex'
  autoload :Parser, 'synvert/core/node_query/parser.racc'
end