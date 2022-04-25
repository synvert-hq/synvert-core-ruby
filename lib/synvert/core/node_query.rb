# frozen_string_literal: true

# NodeQuery defines a node query language, which is a css like syntax for matching nodes.
#
# It supports the following selectors:
#
# * AST node type: +.class+, +.send+
# * attribute value: +[receiver = nil]+, +[message = create]+
# * attribute regex: <code>[key=~/\A:([^'"]+)\z/]</code>, <code>[key!~/\A:([^'"]+)\z/]</code>
# * attribute conditions: +[message != nil]+, +[value > 1]+, +[value >= 1]+, +[value < 1]+, +[value <= 1]+
# * nested attribute: +[caller.message = map]+, +[arguments.size = 2]+
# * first or last child: +.def:first-child+, +.send:last-child+
# * nth-child or nth-last-child: +.def:nth-child(2)+, +.send:nth-last-child(2)+
# * descendant: +.class .send+
# * child: +.class > .def+
# * following sibling: <code>.def:first-child + .def</code>
# * subsequnt sibling: +.def:first-child ~ .def+
# * has: +.class:has(.def)+
#
# It also supports some custom selectors:
#
# * nested selector: +.send[arguments = [size = 2][first = .sym][last = .hash]]+
# * array value: +.send[arguments = (a, b)]+
# * IN operator: +.send[message IN (try, try!)]+
# * NOT IN operator: +.send[message NOT IN (create, build)]+
# * INCLUDES operator: +.send[arguments INCLUDES &block]+
# * dynamic attribute value: +.hash > .pair[key={{value}}]+
#
# @example
#   # it matches methods call nodes, like `puts message` or `p message`
#   Synvert::Core::NodeQuery::Parser.parse('.send[receiver = nil][message IN (puts, p)]').query_nodes(node)
module Synvert::Core::NodeQuery
  autoload :Compiler, 'synvert/core/node_query/compiler'
  autoload :Lexer, 'synvert/core/node_query/lexer.rex'
  autoload :Parser, 'synvert/core/node_query/parser.racc'
end
