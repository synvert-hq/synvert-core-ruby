# CHANGELOG

## 0.4.3

* Add parent_class for :class node
* Move process_with_node to instance
* Add Instance#process_with_other_node
* Fix indent for append action

## 0.4.2

* Do not rewrite code in {{ }} in synvert can't rewrite it
* Fix indent for replace_with action

## 0.4.1

* Add Rewriter::Helper module to provide common helper methods.

## 0.4.0 (2014-07-26)

* Add erb support
* Add replace_erb_stmt_with_expr dsl
* Improve Parser::AST::Node#to_value

## 0.3.0 (2014-07-12)

* Rename node.source(instance) to node.to_source
* Add has_key? and hash_value helper methods for hash node
* Fix Instance#check_conflict_actions

## 0.2.0 (2014-05-16)

* Add remove_file dsl
* Add warn dsl
* Return empty array if no available rewriters

## 0.1.0 (2014-05-04)

* Abstract from synvert
