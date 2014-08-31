# CHANGELOG

## 0.5.2

* Add body for :defs node

## 0.5.1

* Remove Rewriter::Instance class methods current and current_source

## 0.5.0 (2014-08-21)

* Add group to rewriter
* Add parent_class for :class node
* Add Rewriter::Helper module to provide common helper methods.
* Fix indent for append and replace_with action
* Cache file source and ast

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
